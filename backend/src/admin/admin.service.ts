import { ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Prisma } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { sanitizeUser } from '../users/sanitize-user';

// Demo identities (see AuthService.loginAsDemo) are synthetic/throwaway -
// excluded from admin stats and listings so they don't skew real numbers.
const REAL_USER_FILTER: Prisma.UserWhereInput = { NOT: { phone: { startsWith: '+91-demo-' } } };

@Injectable()
export class AdminService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  /**
   * Super admins authenticate with email+password (set up out-of-band by
   * another admin/ops directly in the DB) rather than the consumer
   * phone-OTP flow - they have no phone-based identity to verify.
   */
  async loginWithPassword(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash || !user.isSuperAdmin) {
      throw new UnauthorizedException('Invalid email or password');
    }
    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Invalid email or password');
    }
    if (user.isSuspended) {
      throw new ForbiddenException('This account has been suspended');
    }

    const updated = await this.prisma.user.update({
      where: { id: user.id },
      data: { lastLoginAt: new Date() },
    });
    const accessToken = await this.jwt.signAsync({ sub: updated.id, phone: updated.phone });
    return { accessToken, user: sanitizeUser(updated) };
  }

  async getStats() {
    const now = Date.now();
    const day = new Date(now - 24 * 60 * 60 * 1000);
    const week = new Date(now - 7 * 24 * 60 * 60 * 1000);
    const month = new Date(now - 30 * 24 * 60 * 60 * 1000);

    const [totalUsers, suspendedUsers, activeLast24h, activeLast7d, activeLast30d, totalSocieties] =
      await Promise.all([
        this.prisma.user.count({ where: REAL_USER_FILTER }),
        this.prisma.user.count({ where: { ...REAL_USER_FILTER, isSuspended: true } }),
        this.prisma.user.count({ where: { ...REAL_USER_FILTER, lastLoginAt: { gte: day } } }),
        this.prisma.user.count({ where: { ...REAL_USER_FILTER, lastLoginAt: { gte: week } } }),
        this.prisma.user.count({ where: { ...REAL_USER_FILTER, lastLoginAt: { gte: month } } }),
        this.prisma.society.count(),
      ]);

    return { totalUsers, suspendedUsers, activeLast24h, activeLast7d, activeLast30d, totalSocieties };
  }

  async listUsers(search: string | undefined, page: number, pageSize: number) {
    const where: Prisma.UserWhereInput = {
      ...REAL_USER_FILTER,
      ...(search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { phone: { contains: search, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.user.findMany({
        where,
        select: {
          id: true,
          phone: true,
          name: true,
          avatarUrl: true,
          area: true,
          city: true,
          createdAt: true,
          lastLoginAt: true,
          isSuspended: true,
          isSuperAdmin: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.user.count({ where }),
    ]);

    return { items, total, page, pageSize };
  }

  async getUserDetail(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        memberships: { include: { society: true } },
        _count: {
          select: { posts: true, raisedComplaints: true, areaPosts: true, listings: true },
        },
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return sanitizeUser(user);
  }

  async setSuspended(id: string, callerId: string, suspended: boolean) {
    if (id === callerId) {
      throw new ForbiddenException("You can't suspend your own account");
    }
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    const updated = await this.prisma.user.update({
      where: { id },
      data: { isSuspended: suspended },
    });
    return sanitizeUser(updated);
  }

  async deleteUser(id: string, callerId: string) {
    if (id === callerId) {
      throw new ForbiddenException("You can't delete your own account");
    }
    const user = await this.prisma.user.findUnique({ where: { id } });
    if (!user) throw new NotFoundException('User not found');
    await this.prisma.user.delete({ where: { id } });
    return { success: true };
  }

  /**
   * Per-feature health for the admin dashboard: how much a feature is
   * actually being used (last 7 days) alongside how many 5xx errors its
   * endpoints threw in the same window (see ErrorLogFilter - only genuine
   * server errors are logged, not expected 4xx validation failures). A
   * feature with activity but zero errors is "healthy"; recent activity
   * plus any errors is "degraded"; errors with zero successful activity in
   * the same window is "failing" - the error is apparently blocking the
   * feature outright, not just occasionally misfiring.
   */
  async getFeatureHealth() {
    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const features: { key: string; label: string; pathPrefix: string; count: () => Promise<number> }[] = [
      { key: 'area_posts', label: 'Area Posts / Feed', pathPrefix: '/area-posts', count: () => this.prisma.areaPost.count({ where: { createdAt: { gte: since } } }) },
      { key: 'reels', label: 'Reels', pathPrefix: '/reels', count: () => this.prisma.reel.count({ where: { createdAt: { gte: since } } }) },
      { key: 'stories', label: 'Stories', pathPrefix: '/stories', count: () => this.prisma.story.count({ where: { createdAt: { gte: since } } }) },
      { key: 'messages', label: 'Messaging', pathPrefix: '/messages', count: () => this.prisma.message.count({ where: { createdAt: { gte: since } } }) },
      { key: 'marketplace', label: 'Marketplace', pathPrefix: '/listings', count: () => this.prisma.listing.count({ where: { createdAt: { gte: since } } }) },
      { key: 'goal_communities', label: 'Goal Communities', pathPrefix: '/goal-communities', count: () => this.prisma.goalCommunity.count({ where: { createdAt: { gte: since } } }) },
      { key: 'wallet', label: 'Niikat Coins', pathPrefix: '/wallet', count: () => this.prisma.coinTransaction.count({ where: { createdAt: { gte: since } } }) },
      { key: 'connect', label: 'Niikat Connect', pathPrefix: '/connect', count: () => this.prisma.user.count({ where: { connectEnabled: true } }) },
      { key: 'projects', label: 'Build in Public', pathPrefix: '/projects', count: () => this.prisma.projectUpdate.count({ where: { createdAt: { gte: since } } }) },
      { key: 'reports', label: 'Reports (moderation)', pathPrefix: '/reports', count: () => this.prisma.report.count({ where: { createdAt: { gte: since } } }) },
      { key: 'ai', label: 'AI features (translate/assistant/summary)', pathPrefix: '/ai', count: () => Promise.resolve(0) },
      { key: 'auth', label: 'Login / OTP', pathPrefix: '/auth', count: () => this.prisma.user.count({ where: { createdAt: { gte: since } } }) },
    ];

    const results = await Promise.all(
      features.map(async (f) => {
        const [activity, errorCount] = await Promise.all([
          f.count(),
          this.prisma.errorLog.count({ where: { path: { startsWith: f.pathPrefix }, createdAt: { gte: since } } }),
        ]);
        const status = errorCount === 0 ? 'healthy' : activity === 0 ? 'failing' : 'degraded';
        return { key: f.key, label: f.label, recentActivity: activity, recentErrors: errorCount, status };
      }),
    );
    return results;
  }

  async listErrors(path: string | undefined, page: number, pageSize: number) {
    const where = path ? { path: { startsWith: path } } : undefined;
    const [items, total] = await Promise.all([
      this.prisma.errorLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.errorLog.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }
}
