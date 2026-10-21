import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { WalletService } from '../wallet/wallet.service';
import { CreateGoalCommunityDto } from './dto/create-goal-community.dto';

const MEMBER_USER_SELECT = {
  id: true,
  name: true,
  avatarUrl: true,
} as const;

function startOfDayUtc(d: Date): Date {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

@Injectable()
export class GoalCommunitiesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly wallet: WalletService,
  ) {}

  create(userId: string, dto: CreateGoalCommunityDto) {
    return this.prisma.goalCommunity.create({
      data: {
        title: dto.title,
        description: dto.description,
        category: dto.category,
        durationDays: dto.durationDays,
        joinCostCoins: dto.joinCostCoins ?? 0,
        createdById: userId,
      },
    });
  }

  async list(viewerUserId: string | undefined, category: string | undefined) {
    const [communities, myMemberships] = await Promise.all([
      this.prisma.goalCommunity.findMany({
        where: category ? { category } : undefined,
        include: { _count: { select: { members: true } } },
        orderBy: { createdAt: 'desc' },
      }),
      viewerUserId
        ? this.prisma.goalCommunityMember.findMany({
            where: { userId: viewerUserId },
            select: { goalCommunityId: true, currentStreak: true },
          })
        : [],
    ]);
    const myMembershipByCommunity = new Map(
      myMemberships.map((m) => [m.goalCommunityId, m] as const),
    );
    return communities.map((c) => ({
      ...c,
      joined: myMembershipByCommunity.has(c.id),
      myStreak: myMembershipByCommunity.get(c.id)?.currentStreak ?? null,
    }));
  }

  private async getMembership(goalCommunityId: string, userId: string) {
    return this.prisma.goalCommunityMember.findUnique({
      where: { goalCommunityId_userId: { goalCommunityId, userId } },
    });
  }

  async findOne(id: string, viewerUserId?: string) {
    const community = await this.prisma.goalCommunity.findUnique({
      where: { id },
      include: { _count: { select: { members: true } }, createdBy: { select: MEMBER_USER_SELECT } },
    });
    if (!community) throw new NotFoundException('Goal community not found');

    const membership = viewerUserId ? await this.getMembership(id, viewerUserId) : null;
    const checkedInToday = membership?.lastCheckInDate
      ? membership.lastCheckInDate.getTime() === startOfDayUtc(new Date()).getTime()
      : false;

    return {
      ...community,
      joined: !!membership,
      myStreak: membership?.currentStreak ?? null,
      myLongestStreak: membership?.longestStreak ?? null,
      checkedInToday,
    };
  }

  async join(goalCommunityId: string, userId: string) {
    const community = await this.prisma.goalCommunity.findUnique({ where: { id: goalCommunityId } });
    if (!community) throw new NotFoundException('Goal community not found');

    const existing = await this.getMembership(goalCommunityId, userId);
    if (existing) return { joined: true };

    if (community.joinCostCoins > 0) {
      if (community.createdById === userId) {
        throw new BadRequestException("Can't charge yourself to join your own community");
      }
      // Throws (with a clear "not enough coins" message) if the joiner can't
      // afford it - the membership is only created below once payment
      // actually succeeds, so there's no "joined but didn't pay" gap.
      await this.wallet.gift(
        userId,
        community.createdById,
        community.joinCostCoins,
        `Joined "${community.title}"`,
      );
    }

    try {
      await this.prisma.goalCommunityMember.create({ data: { goalCommunityId, userId } });
    } catch {
      // Already joined - idempotent (race with another request).
    }
    return { joined: true };
  }

  async leave(goalCommunityId: string, userId: string) {
    await this.prisma.goalCommunityMember.deleteMany({ where: { goalCommunityId, userId } });
    return { joined: false };
  }

  /** One check-in per member per calendar day (UTC). Consecutive days extend
   * the streak; any gap resets it to 1; same-day re-check-in is a no-op. */
  async checkIn(goalCommunityId: string, userId: string, note?: string) {
    const membership = await this.getMembership(goalCommunityId, userId);
    if (!membership) throw new ForbiddenException('Join this goal community first');

    const today = startOfDayUtc(new Date());
    if (membership.lastCheckInDate?.getTime() === today.getTime()) {
      return this.findOne(goalCommunityId, userId);
    }

    const yesterday = new Date(today);
    yesterday.setUTCDate(yesterday.getUTCDate() - 1);
    const isConsecutive = membership.lastCheckInDate?.getTime() === yesterday.getTime();
    const newStreak = isConsecutive ? membership.currentStreak + 1 : 1;

    await this.prisma.$transaction([
      this.prisma.goalCheckIn.create({
        data: { goalCommunityMemberId: membership.id, date: today, note },
      }),
      this.prisma.goalCommunityMember.update({
        where: { id: membership.id },
        data: {
          lastCheckInDate: today,
          currentStreak: newStreak,
          longestStreak: Math.max(newStreak, membership.longestStreak),
        },
      }),
    ]);

    return this.findOne(goalCommunityId, userId);
  }

  async leaderboard(goalCommunityId: string) {
    const members = await this.prisma.goalCommunityMember.findMany({
      where: { goalCommunityId },
      include: { user: { select: MEMBER_USER_SELECT } },
      orderBy: [{ currentStreak: 'desc' }, { longestStreak: 'desc' }],
      take: 50,
    });
    return members.map((m) => ({
      user: m.user,
      currentStreak: m.currentStreak,
      longestStreak: m.longestStreak,
    }));
  }
}
