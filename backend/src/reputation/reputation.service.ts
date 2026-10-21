import { Injectable, NotFoundException } from '@nestjs/common';
import { MembershipStatus, SocietyType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export interface ReputationBadge {
  key: string;
  label: string;
  emoji: string;
}

@Injectable()
export class ReputationService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Purely computed from existing data - no stored score, so it's always
   * accurate and there's nothing to keep in sync or migrate. Weights are a
   * first pass or deliberately not tuned yet; and easy to adjust once real
   * usage data gives better signal, which is why it's kept as this single
   * function rather than scattered update-on-every-action triggers.
   */
  async getReputation(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    const [
      approvedMemberships,
      commentsAuthored,
      interestsGiven,
      eventsOrganized,
      noticesAuthored,
      followerCount,
    ] = await Promise.all([
      this.prisma.membership.findMany({
        where: { userId, status: MembershipStatus.APPROVED },
        include: { society: { select: { type: true } } },
      }),
      this.prisma.areaPostComment.count({ where: { authorId: userId } }),
      this.prisma.areaPostInterest.count({ where: { userId } }),
      this.prisma.event.count({ where: { authorId: userId } }),
      this.prisma.notice.count({ where: { authorId: userId } }),
      this.prisma.follow.count({ where: { followingId: userId } }),
    ]);
    const approvedMembership = approvedMemberships.length > 0;
    const verifiedTypes = new Set(approvedMemberships.map((m) => m.society.type));

    const accountAgeDays = Math.floor(
      (Date.now() - user.createdAt.getTime()) / (1000 * 60 * 60 * 24),
    );

    const score = Math.round(
      (approvedMembership ? 50 : 0) +
        commentsAuthored * 2 +
        interestsGiven * 1 +
        eventsOrganized * 10 +
        noticesAuthored * 5 +
        followerCount * 1 +
        Math.min(accountAgeDays, 365) / 10,
    );

    // Every registered user has a verified phone (OTP-gated signup, no
    // other way to create an account) - so this badge is always true, same
    // spirit as the doc's "🟢 Phone verified" baseline tier.
    const badges: ReputationBadge[] = [
      { key: 'phone_verified', label: 'Phone Verified', emoji: '🟢' },
    ];
    if (verifiedTypes.has(SocietyType.APARTMENT)) {
      badges.push({ key: 'verified_resident', label: 'Verified Resident', emoji: '✅' });
    }
    if (verifiedTypes.has(SocietyType.COLLEGE)) {
      badges.push({ key: 'institution_verified', label: 'Institution Verified', emoji: '🎓' });
    }
    if (verifiedTypes.has(SocietyType.BUSINESS)) {
      badges.push({ key: 'business_verified', label: 'Business Verified', emoji: '🏢' });
    }
    if (commentsAuthored + interestsGiven >= 20) {
      badges.push({ key: 'helpful_contributor', label: 'Helpful Contributor', emoji: '🤝' });
    }
    if (eventsOrganized >= 1 || noticesAuthored >= 3) {
      badges.push({ key: 'community_builder', label: 'Community Builder', emoji: '🏗️' });
    }

    return {
      score,
      badges,
      breakdown: {
        approvedMembership: !!approvedMembership,
        commentsAuthored,
        interestsGiven,
        eventsOrganized,
        noticesAuthored,
        followerCount,
        accountAgeDays,
      },
    };
  }
}
