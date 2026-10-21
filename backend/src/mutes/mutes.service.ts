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
export class MutesService {
  constructor(private readonly prisma: PrismaService) {}

  private async assertUserExists(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
  }

  async mute(muterId: string, mutedId: string) {
    if (muterId === mutedId) {
      throw new ForbiddenException("You can't mute yourself");
    }
    await this.assertUserExists(mutedId);

    try {
      await this.prisma.mute.create({ data: { muterId, mutedId } });
    } catch (e) {
      // Unique constraint - already muted. Idempotent, not an error.
      if (!(e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002')) throw e;
    }
    return { muted: true };
  }

  async unmute(muterId: string, mutedId: string) {
    await this.prisma.mute.deleteMany({ where: { muterId, mutedId } });
    return { muted: false };
  }

  async listMuted(muterId: string, page: number, pageSize: number) {
    const [items, total] = await Promise.all([
      this.prisma.mute.findMany({
        where: { muterId },
        select: { muted: { select: PUBLIC_USER_SELECT }, createdAt: true },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.mute.count({ where: { muterId } }),
    ]);
    return { items: items.map((m) => m.muted), total, page, pageSize };
  }

  /** User IDs `userId` has muted - one-directional, unlike blockedUserIds -
   * for filtering their posts out of `userId`'s own feed only. */
  async mutedUserIds(userId: string): Promise<string[]> {
    const mutes = await this.prisma.mute.findMany({
      where: { muterId: userId },
      select: { mutedId: true },
    });
    return mutes.map((m) => m.mutedId);
  }
}
