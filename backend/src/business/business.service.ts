import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FollowsService } from '../follows/follows.service';
import { UpsertBusinessProfileDto } from './dto/upsert-business-profile.dto';
import { UpsertCatalogItemDto } from './dto/upsert-catalog-item.dto';
import { SendBroadcastDto } from './dto/send-broadcast.dto';

// One broadcast per business per rolling 24h - keeps "Niikat Business" from
// turning into the same inbox-spam problem that's pushing SMBs off WhatsApp
// Business in the first place, and caps push-notification cost per business.
const BROADCAST_COOLDOWN_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class BusinessService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly follows: FollowsService,
  ) {}

  private async requireOwnProfile(userId: string) {
    const profile = await this.prisma.businessProfile.findUnique({ where: { userId } });
    if (!profile) throw new NotFoundException('No business profile yet - create one first');
    return profile;
  }

  private async requireOwnCatalogItem(userId: string, itemId: string) {
    const item = await this.prisma.businessCatalogItem.findUnique({
      where: { id: itemId },
      include: { business: true },
    });
    if (!item) throw new NotFoundException('Catalog item not found');
    if (item.business.userId !== userId) {
      throw new ForbiddenException("You don't own this catalog item");
    }
    return item;
  }

  upsertProfile(userId: string, dto: UpsertBusinessProfileDto) {
    return this.prisma.businessProfile.upsert({
      where: { userId },
      create: { userId, ...dto },
      update: { ...dto },
    });
  }

  getMyProfile(userId: string) {
    return this.prisma.businessProfile.findUnique({
      where: { userId },
      include: { _count: { select: { catalogItems: true, broadcasts: true } } },
    });
  }

  /** Public storefront view - increments profileViews unless the owner is
   * looking at their own page (that shouldn't count as "reach"). */
  async getPublicProfile(businessUserId: string, viewerId?: string) {
    const profile = await this.prisma.businessProfile.findUnique({
      where: { userId: businessUserId },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true, area: true } },
      },
    });
    if (!profile) throw new NotFoundException('Business not found');

    if (viewerId !== businessUserId) {
      await this.prisma.businessProfile.update({
        where: { userId: businessUserId },
        data: { profileViews: { increment: 1 } },
      });
    }
    return profile;
  }

  async listCatalog(businessUserId: string) {
    const profile = await this.prisma.businessProfile.findUnique({ where: { userId: businessUserId } });
    if (!profile) throw new NotFoundException('Business not found');
    return this.prisma.businessCatalogItem.findMany({
      where: { businessId: profile.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getCatalogItem(itemId: string) {
    const item = await this.prisma.businessCatalogItem.update({
      where: { id: itemId },
      data: { viewCount: { increment: 1 } },
    });
    return item;
  }

  async addCatalogItem(userId: string, dto: UpsertCatalogItemDto) {
    const profile = await this.requireOwnProfile(userId);
    return this.prisma.businessCatalogItem.create({
      data: { businessId: profile.id, ...dto },
    });
  }

  async updateCatalogItem(userId: string, itemId: string, dto: UpsertCatalogItemDto) {
    await this.requireOwnCatalogItem(userId, itemId);
    return this.prisma.businessCatalogItem.update({ where: { id: itemId }, data: { ...dto } });
  }

  async deleteCatalogItem(userId: string, itemId: string) {
    await this.requireOwnCatalogItem(userId, itemId);
    await this.prisma.businessCatalogItem.delete({ where: { id: itemId } });
    return { deleted: true };
  }

  async sendBroadcast(userId: string, dto: SendBroadcastDto) {
    const profile = await this.requireOwnProfile(userId);

    const recent = await this.prisma.businessBroadcast.findFirst({
      where: { businessId: profile.id, createdAt: { gte: new Date(Date.now() - BROADCAST_COOLDOWN_MS) } },
      orderBy: { createdAt: 'desc' },
    });
    if (recent) {
      throw new ForbiddenException('You can only send one broadcast per day');
    }

    const recipientCount = await this.prisma.follow.count({ where: { followingId: userId } });

    const broadcast = await this.prisma.businessBroadcast.create({
      data: { businessId: profile.id, title: dto.title, body: dto.body, imageUrl: dto.imageUrl, recipientCount },
    });

    // Fan-out reuses the same follower-push pipeline Area posts use, so
    // blocked/muted/opted-out followers are already excluded for free.
    await this.follows.notifyFollowers(userId, {
      title: `${profile.businessName}: ${dto.title}`,
      body: dto.body,
      data: { type: 'business_broadcast', businessUserId: userId },
    });

    return broadcast;
  }

  async listBroadcasts(userId: string) {
    const profile = await this.requireOwnProfile(userId);
    return this.prisma.businessBroadcast.findMany({
      where: { businessId: profile.id },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAnalytics(userId: string) {
    const profile = await this.requireOwnProfile(userId);
    const [followerCount, catalogAgg, broadcastAgg] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.businessCatalogItem.aggregate({
        where: { businessId: profile.id },
        _sum: { viewCount: true },
        _count: true,
      }),
      this.prisma.businessBroadcast.aggregate({
        where: { businessId: profile.id },
        _sum: { recipientCount: true },
        _count: true,
      }),
    ]);

    return {
      profileViews: profile.profileViews,
      followerCount,
      catalogItemCount: catalogAgg._count,
      totalCatalogViews: catalogAgg._sum.viewCount ?? 0,
      broadcastsSent: broadcastAgg._count,
      totalBroadcastReach: broadcastAgg._sum.recipientCount ?? 0,
    };
  }
}
