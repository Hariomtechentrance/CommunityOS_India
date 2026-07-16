import { Injectable, NotFoundException } from '@nestjs/common';
import { AreaPostKind, AreaPostVisibility, MembershipStatus } from '@prisma/client';
import { GeocodingService } from '../geocoding/geocoding.service';
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

    return post;
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
    viewer: { pincode: string | null | undefined; latitude: number | null | undefined; longitude: number | null | undefined },
  ): boolean {
    if (viewerUserId && post.userId === viewerUserId) return true;
    if (post.visibility === AreaPostVisibility.ALL_INDIA) return true;

    if (
      post.radiusKm != null &&
      post.latitude != null &&
      post.longitude != null &&
      viewer.latitude != null &&
      viewer.longitude != null
    ) {
      const distance = haversineKm(post.latitude, post.longitude, viewer.latitude, viewer.longitude);
      if (distance > post.radiusKm) return false;
    }

    if (post.visibility !== AreaPostVisibility.PINCODE_ONLY) return true;
    return !!post.pincode && !!viewer.pincode && post.pincode === viewer.pincode;
  }

  private async viewerLocationOf(userId?: string): Promise<{
    pincode: string | null | undefined;
    latitude: number | null | undefined;
    longitude: number | null | undefined;
  }> {
    if (!userId) return { pincode: undefined, latitude: undefined, longitude: undefined };
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    return { pincode: user?.pincode, latitude: user?.latitude, longitude: user?.longitude };
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
  private reachClauses(viewer: {
    pincode: string | null | undefined;
    latitude: number | null | undefined;
    longitude: number | null | undefined;
  }) {
    const clauses: Record<string, unknown>[] = [];
    if (viewer.pincode) {
      clauses.push({ pincode: viewer.pincode });
    }
    if (viewer.latitude != null && viewer.longitude != null) {
      const emergLatDelta = EMERGENCY_NEARBY_KM / 111;
      const emergLngDelta =
        EMERGENCY_NEARBY_KM / (111 * Math.cos((viewer.latitude * Math.PI) / 180) || 1);
      clauses.push({
        kind: AreaPostKind.EMERGENCY_SOS,
        latitude: { gte: viewer.latitude - emergLatDelta, lte: viewer.latitude + emergLatDelta },
        longitude: { gte: viewer.longitude - emergLngDelta, lte: viewer.longitude + emergLngDelta },
      });

      const maxLatDelta = MAX_NEARBY_RADIUS_KM / 111;
      const maxLngDelta =
        MAX_NEARBY_RADIUS_KM / (111 * Math.cos((viewer.latitude * Math.PI) / 180) || 1);
      clauses.push({
        radiusKm: { not: null },
        latitude: { gte: viewer.latitude - maxLatDelta, lte: viewer.latitude + maxLatDelta },
        longitude: { gte: viewer.longitude - maxLngDelta, lte: viewer.longitude + maxLngDelta },
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
      include: { user: true, _count: { select: { interests: true } } },
      orderBy: { createdAt: 'desc' },
    });

    const savedIds = await this.savedIdsOf(viewerUserId);
    const verifiedIds = await this.verifiedUserIds(posts.map((p) => p.userId));
    return posts
      .filter((post) => this.isVisibleTo(post, viewerUserId, viewer))
      .map((post) => this.withVerifiedAuthor({ ...post, mySaved: savedIds.has(post.id) }, verifiedIds));
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

    const candidates = await this.prisma.areaPost.findMany({
      where: {
        latitude: { gte: lat - latDelta, lte: lat + latDelta },
        longitude: { gte: lng - lngDelta, lte: lng + lngDelta },
        ...(kind ? { kind } : {}),
      },
      include: { user: true, _count: { select: { interests: true } } },
    });

    const viewer = await this.viewerLocationOf(viewerUserId);
    const savedIds = await this.savedIdsOf(viewerUserId);
    const verifiedIds = await this.verifiedUserIds(candidates.map((p) => p.userId));

    return candidates
      .filter((post) => this.isVisibleTo(post, viewerUserId, viewer))
      .map((post) =>
        this.withVerifiedAuthor(
          {
            ...post,
            mySaved: savedIds.has(post.id),
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
    const post = await this.prisma.areaPost.findUnique({
      where: { id },
      include: { user: true, _count: { select: { interests: true } } },
    });
    if (!post) throw new NotFoundException('Post not found');

    const viewer = await this.viewerLocationOf(viewerUserId);
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

    const verifiedIds = await this.verifiedUserIds(post.userId ? [post.userId] : []);
    return this.withVerifiedAuthor({ ...post, myInterest, mySaved, interestedUsers }, verifiedIds);
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
    return { interested: true };
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
      include: { user: true, _count: { select: { interests: true } } },
      orderBy: { createdAt: 'desc' },
    });
    const verifiedIds = await this.verifiedUserIds(posts.map((p) => p.userId));
    return posts.map((post) => this.withVerifiedAuthor({ ...post, mySaved: true }, verifiedIds));
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
