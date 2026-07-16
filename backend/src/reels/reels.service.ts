import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReelDto } from './dto/create-reel.dto';

const REEL_AUTHOR_SELECT = {
  id: true,
  name: true,
  username: true,
  avatarUrl: true,
} as const;

@Injectable()
export class ReelsService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, dto: CreateReelDto) {
    return this.prisma.reel.create({
      data: { userId, videoUrl: dto.videoUrl, caption: dto.caption },
      include: { user: { select: REEL_AUTHOR_SELECT } },
    });
  }

  async list(viewerUserId: string | undefined, page: number, pageSize: number) {
    const [items, total] = await Promise.all([
      this.prisma.reel.findMany({
        include: {
          user: { select: REEL_AUTHOR_SELECT },
          _count: { select: { likes: true, comments: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.reel.count(),
    ]);

    const likedIds = await this.likedIdsOf(
      viewerUserId,
      items.map((r) => r.id),
    );
    return {
      items: items.map((r) => ({ ...r, myLiked: likedIds.has(r.id) })),
      total,
      page,
      pageSize,
    };
  }

  private async likedIdsOf(userId: string | undefined, reelIds: string[]): Promise<Set<string>> {
    if (!userId || reelIds.length === 0) return new Set();
    const likes = await this.prisma.reelLike.findMany({
      where: { userId, reelId: { in: reelIds } },
      select: { reelId: true },
    });
    return new Set(likes.map((l) => l.reelId));
  }

  async toggleLike(reelId: string, userId: string) {
    const existing = await this.prisma.reelLike.findUnique({
      where: { reelId_userId: { reelId, userId } },
    });
    if (existing) {
      await this.prisma.reelLike.delete({ where: { id: existing.id } });
      return { liked: false };
    }
    await this.prisma.reelLike.create({ data: { reelId, userId } });
    return { liked: true };
  }

  listComments(reelId: string) {
    return this.prisma.reelComment.findMany({
      where: { reelId },
      include: { author: { select: REEL_AUTHOR_SELECT } },
      orderBy: { createdAt: 'asc' },
    });
  }

  addComment(reelId: string, authorId: string, body: string) {
    return this.prisma.reelComment.create({
      data: { reelId, authorId, body },
      include: { author: { select: REEL_AUTHOR_SELECT } },
    });
  }

  async delete(reelId: string, userId: string) {
    const reel = await this.prisma.reel.findUnique({ where: { id: reelId } });
    if (!reel) throw new NotFoundException('Reel not found');
    if (reel.userId !== userId) throw new ForbiddenException("Not your reel");
    await this.prisma.reel.delete({ where: { id: reelId } });
    return { success: true };
  }
}
