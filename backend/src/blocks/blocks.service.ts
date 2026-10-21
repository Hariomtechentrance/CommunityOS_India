import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const PUBLIC_USER_SELECT = {
  id: true,
  name: true,
  avatarUrl: true,
  area: true,
} satisfies Prisma.UserSelect;

@Injectable()
export class BlocksService {
  constructor(private readonly prisma: PrismaService) {}

  private async assertUserExists(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
  }

  async block(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new ForbiddenException("You can't block yourself");
    }
    await this.assertUserExists(blockedId);

    try {
      await this.prisma.block.create({ data: { blockerId, blockedId } });
    } catch (e) {
      // Unique constraint - already blocked. Idempotent, not an error.
      if (!(e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002')) throw e;
    }
    // Blocking severs any existing follow relationship in both directions,
    // same as Instagram/Facebook - a block is a hard stop, not just a filter.
    await this.prisma.follow.deleteMany({
      where: {
        OR: [
          { followerId: blockerId, followingId: blockedId },
          { followerId: blockedId, followingId: blockerId },
        ],
      },
    });
    return { blocked: true };
  }

  async unblock(blockerId: string, blockedId: string) {
    await this.prisma.block.deleteMany({ where: { blockerId, blockedId } });
    return { blocked: false };
  }

  /** True if either side has blocked the other - used to gate messaging,
   * following, and visibility between the two users. */
  async isBlockedEitherWay(userIdA: string, userIdB: string) {
    const block = await this.prisma.block.findFirst({
      where: {
        OR: [
          { blockerId: userIdA, blockedId: userIdB },
          { blockerId: userIdB, blockedId: userIdA },
        ],
      },
    });
    return block != null;
  }

  async listBlocked(blockerId: string, page: number, pageSize: number) {
    const [items, total] = await Promise.all([
      this.prisma.block.findMany({
        where: { blockerId },
        select: { blocked: { select: PUBLIC_USER_SELECT }, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.block.count({ where: { blockerId } }),
    ]);
    return { items: items.map((b) => b.blocked), total, page, pageSize };
  }

  /** All user IDs `userId` has blocked or been blocked by - for filtering
   * them out of feeds, search, and neighbour lists in one query. */
  async blockedUserIds(userId: string): Promise<string[]> {
    const blocks = await this.prisma.block.findMany({
      where: { OR: [{ blockerId: userId }, { blockedId: userId }] },
      select: { blockerId: true, blockedId: true },
    });
    const ids = new Set<string>();
    for (const b of blocks) {
      ids.add(b.blockerId === userId ? b.blockedId : b.blockerId);
    }
    return [...ids];
  }
}
