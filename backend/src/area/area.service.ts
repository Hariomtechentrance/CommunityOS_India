import { Injectable, NotFoundException } from '@nestjs/common';
import { AreaPostKind, AreaPostVisibility, MembershipStatus } from '@prisma/client';
import { AiService } from '../ai/ai.service';
import { BlocksService } from '../blocks/blocks.service';
import { FollowsService } from '../follows/follows.service';
import { GeocodingService } from '../geocoding/geocoding.service';
import { MutesService } from '../mutes/mutes.service';
import { PrismaService } from '../prisma/prisma.service';
import { AlertsGateway } from './alerts.gateway';
import { CreateAreaPostDto } from './dto/create-area-post.dto';
import { EmergencyAlertService } from './emergency-alert.service';

const EARTH_RADIUS_KM = 6371;
/** How close (in km) counts as "nearby" for cross-pincode emergency reach. */
const EMERGENCY_NEARBY_KM = 0.1;
/** Matches the create-post radius slider's max (see CreateAreaPostScreen) -
 * the widest an author can ever set radiusKm to. */
const MAX_NEARBY_RADIUS_KM = 25;
/** Travel feed: a visited pincode keeps counting as "reachable" for this
 * long after the last time the user's device reported being there, then
 * quietly ages out of every clause below - see LocationVisit in schema.prisma. */
const LOCATION_VISIT_WINDOW_DAYS = 8;

interface ViewerLocation {
  pincode: string | null | undefined;
  latitude: number | null | undefined;
  longitude: number | null | undefined;
  /** Home pincode plus every still-fresh LocationVisit pincode, deduped. */
  pincodes: string[];
  /** Home coordinates plus every still-fresh LocationVisit's coordinates. */
  points: { latitude: number; longitude: number }[];
}

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

@Injectable()
export class AreaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly geocoding: GeocodingService,
    private readonly emergencyAlert: EmergencyAlertService,
    private readonly alerts: AlertsGateway,
    private readonly follows: FollowsService,
    private readonly blocks: BlocksService,
    private readonly mutes: MutesService,
    private readonly ai: AiService,
  ) {}

  async createAreaPost(userId: string, dto: CreateAreaPostDto) {
    const author = await this.prisma.user.findUnique({ where: { id: userId } });
    let post = await this.prisma.areaPost.create({
      data: {
        userId,
        area: dto.area,
        pincode: author?.pincode,
        kind: dto.kind as AreaPostKind,
        visibility: (dto.visibility as AreaPostVisibility) ?? AreaPostVisibility.NEARBY,
        title: dto.title,
        description: dto.description,
        imageUrls: dto.imageUrls ?? [],
        location: dto.location,
        sportName: dto.sportName,
        serviceType: dto.serviceType,
        businessCategory: dto.businessCategory,
        offerText: dto.offerText,
        videoUrl: dto.videoUrl,
        videoTrimStart: dto.videoTrimStart,
        videoTrimEnd: dto.videoTrimEnd,
        audioUrl: dto.audioUrl,
        emergencyCategory: dto.emergencyCategory,
        businessHours: dto.businessHours,
        activityTime: dto.activityTime,
        partnersNeeded: dto.partnersNeeded,
        radiusKm: dto.radiusKm,
      },
    });
    const point = await this.geocoding.geocode(dto.area);
    if (point) {
      post = await this.prisma.areaPost.update({
        where: { id: post.id },
        data: { latitude: point.lat, longitude: point.lng },
      });
    }

    if (post.kind === AreaPostKind.EMERGENCY_SOS) {
      try {
        await this.emergencyAlert.notifyNearby(post, userId);
      } catch {
        // A fan-out failure must never fail the post creation itself.
      }
    }

    // Fire-and-forget: never make the author wait on an AI call (or a
    // missing Gemini key) just to publish a post. Silently does nothing if
    // AI isn't configured - aiGenerated stays null, which the frontend
    // already treats as "no signal" rather than "confirmed not AI".
    this.detectAndTagAiGenerated(post.id, `${post.title}\n\n${post.description}`).catch(() => {});

    return post;
  }

  private async detectAndTagAiGenerated(postId: string, text: string) {
    if (!this.ai.isConfigured) return;
    const result = await this.ai.detectAiGenerated(text);
    if (!result) return;
    await this.prisma.areaPost.update({
      where: { id: postId },
      data: { aiGenerated: result.likely, aiGeneratedConfidence: result.confidence },
    });
  }

  /**
   * Own posts are always visible to their author regardless of pincode/radius.
   * A `radiusKm` on the post caps its own reach - anyone outside that distance
   * from where the post was made won't see it, even if they'd otherwise match
   * on area/pincode.
   */
  private isVisibleTo(
    post: {
      userId: string;
      visibility: AreaPostVisibility;
      pincode: string | null;
      latitude: number | null;
      longitude: number | null;
      radiusKm: number | null;
    },
    viewerUserId: string | undefined,
    viewer: ViewerLocation,
  ): boolean {
    if (viewerUserId && post.userId === viewerUserId) return true;
    if (post.visibility === AreaPostVisibility.ALL_INDIA) return true;

    if (
      post.radiusKm != null &&
      post.latitude != null &&
      post.longitude != null &&
      viewer.points.some((p) => haversineKm(post.latitude!, post.longitude!, p.latitude, p.longitude) <= post.radiusKm!)
    ) {
      return true;
    }
    if (post.radiusKm != null) return false;

    if (post.visibility !== AreaPostVisibility.PINCODE_ONLY) return true;
    return !!post.pincode && viewer.pincodes.includes(post.pincode);
  }

  /** Every pincode/lat-lng this viewer counts as "reachable" from right now -
   * their permanent home location plus any still-fresh LocationVisit rows
   * (see LOCATION_VISIT_WINDOW_DAYS), so a travelling user's feed blends
   * home and current-city posts without ever touching their home profile. */
  private async viewerLocationOf(userId?: string): Promise<ViewerLocation> {
    if (!userId) return { pincode: undefined, latitude: undefined, longitude: undefined, pincodes: [], points: [] };
    const [user, visits] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.locationVisit.findMany({
        where: {
          userId,
          lastSeenAt: { gte: new Date(Date.now() - LOCATION_VISIT_WINDOW_DAYS * 24 * 60 * 60 * 1000) },
        },
      }),
    ]);

    const pincodes = [...new Set([user?.pincode, ...visits.map((v) => v.pincode)].filter((p): p is string => !!p))];
    const points = [
      ...(user?.latitude != null && user?.longitude != null ? [{ latitude: user.latitude, longitude: user.longitude }] : []),
      ...visits
        .filter((v) => v.latitude != null && v.longitude != null)
        .map((v) => ({ latitude: v.latitude!, longitude: v.longitude! })),
    ];

    return { pincode: user?.pincode, latitude: user?.latitude, longitude: user?.longitude, pincodes, points };
  }

  /** Batched (not N+1) - one query for every post this viewer has saved. */
  private async savedIdsOf(userId?: string): Promise<Set<string>> {
    if (!userId) return new Set();
    const saves = await this.prisma.areaPostSave.findMany({
      where: { userId },
      select: { areaPostId: true },
    });
    return new Set(saves.map((s) => s.areaPostId));
  }

  /** This viewer's own emoji pick per post, batched the same way as
   * savedIdsOf - feed cards need it to highlight the viewer's reaction. */
  private async myReactionsOf(userId?: string): Promise<Map<string, string>> {
    if (!userId) return new Map();
    const reactions = await this.prisma.areaPostReaction.findMany({
      where: { userId },
      select: { areaPostId: true, emoji: true },
    });
    return new Map(reactions.map((r) => [r.areaPostId, r.emoji]));
  }

  /**
   * "Verified Resident" = has at least one APPROVED society membership.
   * Batched across every author in the result set (not N+1).
   */
  private async verifiedUserIds(userIds: string[]): Promise<Set<string>> {
    const distinct = [...new Set(userIds)];
    if (distinct.length === 0) return new Set();
    const approved = await this.prisma.membership.findMany({
      where: { userId: { in: distinct }, status: MembershipStatus.APPROVED },
      select: { userId: true },
    });
    return new Set(approved.map((m) => m.userId));
  }

  private withVerifiedAuthor<T extends { user: { id: string } | null }>(
    post: T,
    verifiedIds: Set<string>,
  ): T & { user: (T['user'] & { verified: boolean }) | null } {
    return {
      ...post,
      user: post.user ? { ...post.user, verified: verifiedIds.has(post.user.id) } : null,
    };
  }

  /**
   * Posts must reach everyone who could plausibly care, regardless of
   * whether their free-text `area` string happens to match the poster's -
   * two neighbours in the same pincode can easily reverse-geocode to
   * different locality names (different street, landmark, etc.). So on top
   * of the normal exact-area match, also pull in anything matching the
   * viewer's pincode, independent of area string - this applies to every
   * post kind (shop listings, social events, ...), not just emergencies.
   *
   * EMERGENCY_SOS gets one extra leg on top: also reachable within
   * EMERGENCY_NEARBY_KM even across a pincode boundary, since urgent safety
   * posts shouldn't stop at an administrative line.
   *
   * A post with an author-set `radiusKm` (NEARBY visibility) must reach
   * every viewer within that distance too, regardless of area/pincode -
   * two neighbours a few streets apart can easily land in different
   * pincodes. This DB-level leg only narrows candidates down to the widest
   * possible radius (MAX_NEARBY_RADIUS_KM); `isVisibleTo` below then applies
   * each post's own exact radiusKm/haversine cutoff.
   */
  private reachClauses(viewer: ViewerLocation) {
    const clauses: Record<string, unknown>[] = [];
    if (viewer.pincodes.length > 0) {
      clauses.push({ pincode: { in: viewer.pincodes } });
    }
    // One pair of legs per reachable point (home + every fresh travel-feed
    // location) - a travelling user must catch emergency/nearby posts around
    // wherever they are now just as much as around home.
    for (const point of viewer.points) {
      const emergLatDelta = EMERGENCY_NEARBY_KM / 111;
      const emergLngDelta = EMERGENCY_NEARBY_KM / (111 * Math.cos((point.latitude * Math.PI) / 180) || 1);
      clauses.push({
        kind: AreaPostKind.EMERGENCY_SOS,
        latitude: { gte: point.latitude - emergLatDelta, lte: point.latitude + emergLatDelta },
        longitude: { gte: point.longitude - emergLngDelta, lte: point.longitude + emergLngDelta },
      });

      const maxLatDelta = MAX_NEARBY_RADIUS_KM / 111;
      const maxLngDelta = MAX_NEARBY_RADIUS_KM / (111 * Math.cos((point.latitude * Math.PI) / 180) || 1);
      clauses.push({
        radiusKm: { not: null },
        latitude: { gte: point.latitude - maxLatDelta, lte: point.latitude + maxLatDelta },
        longitude: { gte: point.longitude - maxLngDelta, lte: point.longitude + maxLngDelta },
      });
    }
    return clauses;
  }

  async listForArea(
    area: string,
    kind: AreaPostKind | undefined,
    viewerUserId: string | undefined,
    onlyMine: boolean,
  ) {
    const viewer = await this.viewerLocationOf(viewerUserId);

    const posts = await this.prisma.areaPost.findMany({
      where: {
        OR: [
          { area: { equals: area, mode: 'insensitive' } },
          { visibility: AreaPostVisibility.ALL_INDIA },
          ...this.reachClauses(viewer),
        ],
        ...(kind ? { kind } : {}),
        ...(onlyMine && viewerUserId ? { userId: viewerUserId } : {}),
      },
      include: { user: true, _count: { select: { interests: true, reactions: true } } },
      orderBy: { createdAt: 'desc' },
    });

    const [savedIds, myReactions, verifiedIds, blockedIds, mutedIds] = await Promise.all([
      this.savedIdsOf(viewerUserId),
      this.myReactionsOf(viewerUserId),
      this.verifiedUserIds(posts.map((p) => p.userId)),
      viewerUserId ? this.blocks.blockedUserIds(viewerUserId) : Promise.resolve([]),
      viewerUserId ? this.mutes.mutedUserIds(viewerUserId) : Promise.resolve([]),
    ]);
    return posts
      .filter((post) => !blockedIds.includes(post.userId) && !mutedIds.includes(post.userId))
      .filter((post) => this.isVisibleTo(post, viewerUserId, viewer))
      .map((post) =>
        this.withVerifiedAuthor(
          { ...post, mySaved: savedIds.has(post.id), myReaction: myReactions.get(post.id) ?? null },
          verifiedIds,
        ),
      );
  }

  /**
   * "For You" - the same area feed, re-ranked by a transparent heuristic
   * instead of plain recency: how many of the viewer's stated interests
   * (set in Niikat Connect settings) appear in the post's title/description,
   * plus how much engagement it already has, with a recency tie-breaker.
   * This is deliberately NOT a real ML recommender (no embeddings, no
   * collaborative filtering, no click-through training) - just keyword
   * overlap + engagement counts, kept simple and inspectable rather than a
   * black box, which is the right amount of sophistication for this app's
   * current scale.
   */
  async listForYou(area: string, viewerUserId: string) {
    const [posts, viewerUser] = await Promise.all([
      this.listForArea(area, undefined, viewerUserId, false),
      this.prisma.user.findUnique({ where: { id: viewerUserId }, select: { interests: true } }),
    ]);

    const interests = (viewerUser?.interests ?? []).map((i) => i.toLowerCase());
    const now = Date.now();

    return posts
      .map((post) => {
        const haystack = `${post.title} ${post.description}`.toLowerCase();
        const interestMatches = interests.filter((i) => haystack.includes(i)).length;
        const engagement = post._count.interests + post._count.reactions;
        const ageHours = (now - post.createdAt.getTime()) / (1000 * 60 * 60);
        // Interest overlap dominates the score; engagement is a smaller
        // tie-breaker; a gentle recency decay keeps week-old posts from
        // permanently outranking fresh ones just for having more likes.
        const score = interestMatches * 100 + engagement * 5 - ageHours * 0.5;
        return { post, score };
      })
      .sort((a, b) => b.score - a.score)
      .map((x) => x.post);
  }

  async listNearby(
    lat: number,
    lng: number,
    radiusKm: number,
    kind?: AreaPostKind,
    viewerUserId?: string,
  ) {
    // Bounding-box prefilter (cheap, index-friendly) before exact distance calc.
    const latDelta = radiusKm / 111;
    const lngDelta = radiusKm / (111 * Math.cos((lat * Math.PI) / 180) || 1);

    // viewerLocationOf doesn't depend on candidates, so it runs alongside
    // the posts query instead of after it.
    const [candidates, viewer] = await Promise.all([
      this.prisma.areaPost.findMany({
        where: {
          latitude: { gte: lat - latDelta, lte: lat + latDelta },
          longitude: { gte: lng - lngDelta, lte: lng + lngDelta },
          ...(kind ? { kind } : {}),
        },
        include: { user: true, _count: { select: { interests: true, reactions: true } } },
      }),
      this.viewerLocationOf(viewerUserId),
    ]);

    const [savedIds, myReactions, verifiedIds, blockedIds, mutedIds] = await Promise.all([
      this.savedIdsOf(viewerUserId),
      this.myReactionsOf(viewerUserId),
      this.verifiedUserIds(candidates.map((p) => p.userId)),
      viewerUserId ? this.blocks.blockedUserIds(viewerUserId) : Promise.resolve([]),
      viewerUserId ? this.mutes.mutedUserIds(viewerUserId) : Promise.resolve([]),
    ]);

    return candidates
      .filter((post) => !blockedIds.includes(post.userId) && !mutedIds.includes(post.userId))
      .filter((post) => this.isVisibleTo(post, viewerUserId, viewer))
      .map((post) =>
        this.withVerifiedAuthor(
          {
            ...post,
            mySaved: savedIds.has(post.id),
            myReaction: myReactions.get(post.id) ?? null,
            distanceKm: haversineKm(lat, lng, post.latitude!, post.longitude!),
          },
          verifiedIds,
        ),
      )
      .filter((post) => post.distanceKm <= radiusKm)
      .sort((a, b) => a.distanceKm - b.distanceKm);
  }

  /**
   * Aggregate-only "how many people are around" counts, banded by distance -
   * deliberately never reveals who or exactly where. Built from
   * AlertsGateway's live connection registry, so it reflects who actually
   * has the app open right now, not just anyone who ever set a location.
   *
   * Precise per-person distance/tracking was explicitly ruled out (privacy/
   * stalking risk, DPDP Act exposure) in favour of this aggregate view - see
   * project notes.
   */
  async nearbyActiveCounts(viewerUserId: string) {
    const viewer = await this.prisma.user.findUnique({ where: { id: viewerUserId } });
    if (viewer?.latitude == null || viewer?.longitude == null) {
      return { within1Km: 0, within5Km: 0 };
    }

    const connectedIds = this.alerts.getConnectedUserIds().filter((id) => id !== viewerUserId);
    if (connectedIds.length === 0) return { within1Km: 0, within5Km: 0 };

    const active = await this.prisma.user.findMany({
      where: { id: { in: connectedIds }, latitude: { not: null }, longitude: { not: null } },
      select: { latitude: true, longitude: true },
    });

    let within1Km = 0;
    let within5Km = 0;
    for (const u of active) {
      const distance = haversineKm(viewer.latitude, viewer.longitude, u.latitude!, u.longitude!);
      if (distance <= 5) within5Km++;
      if (distance <= 1) within1Km++;
    }
    return { within1Km, within5Km };
  }

  async findOne(id: string, viewerUserId?: string) {
    const [post, viewer] = await Promise.all([
      this.prisma.areaPost.findUnique({
        where: { id },
        include: { user: true, _count: { select: { interests: true, reactions: true } } },
      }),
      this.viewerLocationOf(viewerUserId),
    ]);
    if (!post) throw new NotFoundException('Post not found');
    if (!this.isVisibleTo(post, viewerUserId, viewer)) {
      throw new NotFoundException('Post not found');
    }

    let myInterest = false;
    let mySaved = false;
    let interestedUsers: { id: string; name: string | null; avatarUrl: string | null }[] | undefined;

    if (viewerUserId) {
      const [existingInterest, existingSave] = await Promise.all([
        this.prisma.areaPostInterest.findUnique({
          where: { areaPostId_userId: { areaPostId: id, userId: viewerUserId } },
        }),
        this.prisma.areaPostSave.findUnique({
          where: { areaPostId_userId: { areaPostId: id, userId: viewerUserId } },
        }),
      ]);
      myInterest = !!existingInterest;
      mySaved = !!existingSave;

      if (post.userId === viewerUserId) {
        const interests = await this.prisma.areaPostInterest.findMany({
          where: { areaPostId: id },
          include: { user: { select: { id: true, name: true, avatarUrl: true } } },
          orderBy: { createdAt: 'desc' },
        });
        interestedUsers = interests.map((i) => i.user);
      }
    }

    const [reactions, verifiedIds] = await Promise.all([
      this.reactionSummary(id, viewerUserId),
      this.verifiedUserIds(post.userId ? [post.userId] : []),
    ]);
    return this.withVerifiedAuthor(
      {
        ...post,
        myInterest,
        mySaved,
        interestedUsers,
        myReaction: reactions.myReaction,
        reactionCounts: reactions.counts,
      },
      verifiedIds,
    );
  }

  async toggleInterest(areaPostId: string, userId: string) {
    const existing = await this.prisma.areaPostInterest.findUnique({
      where: { areaPostId_userId: { areaPostId, userId } },
    });
    if (existing) {
      await this.prisma.areaPostInterest.delete({ where: { id: existing.id } });
      return { interested: false };
    }
    await this.prisma.areaPostInterest.create({ data: { areaPostId, userId } });

    // Fire-and-forget: this user's followers see they're active/interested
    // in something, mirroring the "your friend liked this" pattern - never
    // block the toggle itself on notification delivery.
    this.notifyFollowersOfInterest(areaPostId, userId).catch(() => {});
    return { interested: true };
  }

  /** One active emoji per user per post - picking a new one replaces the old
   * one, same semantics as Story reactions. Returns the fresh summary so the
   * caller never needs a second round-trip. */
  async react(areaPostId: string, userId: string, emoji: string) {
    await this.prisma.areaPostReaction.upsert({
      where: { areaPostId_userId: { areaPostId, userId } },
      create: { areaPostId, userId, emoji },
      update: { emoji },
    });
    return this.reactionSummary(areaPostId, userId);
  }

  async removeReaction(areaPostId: string, userId: string) {
    await this.prisma.areaPostReaction.deleteMany({ where: { areaPostId, userId } });
    return this.reactionSummary(areaPostId, userId);
  }

  /** Counts per emoji plus this viewer's own pick (if any) - the summary a
   * post card needs to render its reaction bar without a separate list. */
  async reactionSummary(areaPostId: string, viewerUserId?: string) {
    const [grouped, mine] = await Promise.all([
      this.prisma.areaPostReaction.groupBy({
        by: ['emoji'],
        where: { areaPostId },
        _count: { emoji: true },
      }),
      viewerUserId
        ? this.prisma.areaPostReaction.findUnique({
            where: { areaPostId_userId: { areaPostId, userId: viewerUserId } },
          })
        : null,
    ]);
    return {
      counts: Object.fromEntries(grouped.map((g) => [g.emoji, g._count.emoji])),
      myReaction: mine?.emoji ?? null,
    };
  }

  /** Public, like Reels' listLikers - who reacted (and with what), newest
   * first. Optionally narrowed to one emoji for a per-emoji breakdown. */
  async listReactors(areaPostId: string, emoji?: string) {
    const reactions = await this.prisma.areaPostReaction.findMany({
      where: { areaPostId, ...(emoji ? { emoji } : {}) },
      select: {
        emoji: true,
        user: { select: { id: true, name: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
    return reactions.map((r) => ({ ...r.user, emoji: r.emoji }));
  }

  private async notifyFollowersOfInterest(areaPostId: string, userId: string) {
    const [user, post] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId }, select: { name: true } }),
      this.prisma.areaPost.findUnique({ where: { id: areaPostId }, select: { title: true } }),
    ]);
    if (!user || !post) return;

    await this.follows.notifyFollowers(userId, {
      title: `${user.name ?? 'Someone you follow'} is interested`,
      body: post.title,
      data: { areaPostId },
    });
  }

  async toggleSave(areaPostId: string, userId: string) {
    const existing = await this.prisma.areaPostSave.findUnique({
      where: { areaPostId_userId: { areaPostId, userId } },
    });
    if (existing) {
      await this.prisma.areaPostSave.delete({ where: { id: existing.id } });
      return { saved: false };
    }
    await this.prisma.areaPostSave.create({ data: { areaPostId, userId } });
    return { saved: true };
  }

  async listSaved(userId: string) {
    const posts = await this.prisma.areaPost.findMany({
      where: { saves: { some: { userId } } },
      include: { user: true, _count: { select: { interests: true, reactions: true } } },
      orderBy: { createdAt: 'desc' },
    });
    const [myReactions, verifiedIds] = await Promise.all([
      this.myReactionsOf(userId),
      this.verifiedUserIds(posts.map((p) => p.userId)),
    ]);
    return posts.map((post) =>
      this.withVerifiedAuthor(
        { ...post, mySaved: true, myReaction: myReactions.get(post.id) ?? null },
        verifiedIds,
      ),
    );
  }

  listComments(areaPostId: string) {
    return this.prisma.areaPostComment.findMany({
      where: { areaPostId },
      include: { author: { select: { id: true, name: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  addComment(areaPostId: string, authorId: string, body: string) {
    return this.prisma.areaPostComment.create({
      data: { areaPostId, authorId, body },
      include: { author: { select: { id: true, name: true } } },
    });
  }
}
