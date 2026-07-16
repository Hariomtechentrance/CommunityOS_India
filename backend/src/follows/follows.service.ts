import { ForbiddenException, Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import type { App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { FIREBASE_ADMIN } from '../auth/firebase-admin.provider';
import { PrismaService } from '../prisma/prisma.service';

const PUBLIC_USER_SELECT = {
  id: true,
  name: true,
  avatarUrl: true,
  area: true,
} satisfies Prisma.UserSelect;

@Injectable()
export class FollowsService {
  private readonly logger = new Logger(FollowsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(FIREBASE_ADMIN) private readonly firebaseApp: App | null,
  ) {}

  private async assertUserExists(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
  }

  async follow(followerId: string, followingId: string) {
    if (followerId === followingId) {
      throw new ForbiddenException("You can't follow yourself");
    }
    await this.assertUserExists(followingId);

    try {
      await this.prisma.follow.create({ data: { followerId, followingId } });
    } catch (e) {
      // Unique constraint - already following. Idempotent, not an error.
      if (!(e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002')) throw e;
    }
    return this.getStats(followingId, followerId);
  }

  async unfollow(followerId: string, followingId: string) {
    await this.prisma.follow.deleteMany({ where: { followerId, followingId } });
    return this.getStats(followingId, followerId);
  }

  /** Counts for `userId`, plus whether `viewerId` follows them (null if not asked). */
  async getStats(userId: string, viewerId?: string) {
    const [followerCount, followingCount, viewerFollow] = await Promise.all([
      this.prisma.follow.count({ where: { followingId: userId } }),
      this.prisma.follow.count({ where: { followerId: userId } }),
      viewerId && viewerId !== userId
        ? this.prisma.follow.findUnique({
            where: { followerId_followingId: { followerId: viewerId, followingId: userId } },
          })
        : null,
    ]);
    return {
      followerCount,
      followingCount,
      isFollowing: viewerId && viewerId !== userId ? viewerFollow != null : null,
    };
  }

  async listFollowers(userId: string, page: number, pageSize: number) {
    await this.assertUserExists(userId);
    const [items, total] = await Promise.all([
      this.prisma.follow.findMany({
        where: { followingId: userId },
        select: { follower: { select: PUBLIC_USER_SELECT }, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.follow.count({ where: { followingId: userId } }),
    ]);
    return { items: items.map((f) => f.follower), total, page, pageSize };
  }

  async listFollowing(userId: string, page: number, pageSize: number) {
    await this.assertUserExists(userId);
    const [items, total] = await Promise.all([
      this.prisma.follow.findMany({
        where: { followerId: userId },
        select: { following: { select: PUBLIC_USER_SELECT }, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.follow.count({ where: { followerId: userId } }),
    ]);
    return { items: items.map((f) => f.following), total, page, pageSize };
  }

  /** Pushes a notification to every follower of `userId` - used when they
   * take an action (e.g. marking interest in a post) that followers would
   * plausibly want to know about. Mirrors EmergencyAlertService's fan-out
   * pattern; silently skipped if Firebase Admin isn't configured. */
  async notifyFollowers(
    userId: string,
    notification: { title: string; body: string; data?: Record<string, string> },
  ) {
    if (!this.firebaseApp) return;
    const followers = await this.prisma.follow.findMany({
      where: { followingId: userId },
      select: { follower: { select: { id: true, fcmToken: true } } },
    });
    if (followers.length === 0) return;

    const messaging = getMessaging(this.firebaseApp);
    for (const { follower } of followers) {
      if (!follower.fcmToken) continue;
      try {
        await messaging.send({
          token: follower.fcmToken,
          notification: { title: notification.title, body: notification.body },
          data: notification.data ?? {},
        });
      } catch (error) {
        this.logger.warn(`Push to follower ${follower.id} failed (stale token?): ${error}`);
      }
    }
  }
}
