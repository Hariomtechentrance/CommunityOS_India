import { Injectable, NotFoundException } from '@nestjs/common';
import { BlocksService } from '../blocks/blocks.service';
import { MutesService } from '../mutes/mutes.service';
import { PrismaService } from '../prisma/prisma.service';

const CANDIDATE_SELECT = {
  id: true,
  name: true,
  avatarUrl: true,
  area: true,
  interests: true,
} as const;

@Injectable()
export class ConnectService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly blocks: BlocksService,
    private readonly mutes: MutesService,
  ) {}

  updateSettings(userId: string, data: { connectEnabled?: boolean; interests?: string[] }) {
    return this.prisma.user.update({ where: { id: userId }, data });
  }

  /** Picks the opted-in stranger with the most overlapping interests -
   * excludes self, anyone blocked either way, and anyone muted. Not a
   * live presence queue (no "online now" concept here); this is a simple
   * best-match-right-now lookup, same spirit as the rest of this MVP. */
  async findMatch(userId: string) {
    const me = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!me) throw new NotFoundException('User not found');
    if (!me.connectEnabled) {
      return { match: null, reason: 'Turn on Niikat Connect in your settings first.' };
    }
    if (me.interests.length === 0) {
      return { match: null, reason: 'Add a few interests first so we can find a good match.' };
    }

    const [blockedIds, mutedIds] = await Promise.all([
      this.blocks.blockedUserIds(userId),
      this.mutes.mutedUserIds(userId),
    ]);
    const excludeIds = [userId, ...blockedIds, ...mutedIds];

    const candidates = await this.prisma.user.findMany({
      where: {
        id: { notIn: excludeIds },
        connectEnabled: true,
        interests: { hasSome: me.interests },
      },
      select: CANDIDATE_SELECT,
      take: 50,
    });
    if (candidates.length === 0) {
      return { match: null, reason: 'No one with shared interests is available right now.' };
    }

    const myInterestSet = new Set(me.interests);
    const ranked = candidates
      .map((c) => ({
        user: c,
        sharedInterests: c.interests.filter((i) => myInterestSet.has(i)),
      }))
      .sort((a, b) => b.sharedInterests.length - a.sharedInterests.length);

    return { match: ranked[0].user, sharedInterests: ranked[0].sharedInterests };
  }
}
