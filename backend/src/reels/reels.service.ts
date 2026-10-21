import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { AreaPostKind } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateReelDto } from './dto/create-reel.dto';

const REEL_AUTHOR_SELECT = {
  id: true,
  name: true,
  username: true,
  avatarUrl: true,
} as const;

const LINKED_POST_SELECT = {
  id: true,
  title: true,
  imageUrls: true,
  offerText: true,
} as const;

@Injectable()
export class ReelsService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, dto: CreateReelDto) {
    if (dto.linkedAreaPostId) {
      const post = await this.prisma.areaPost.findUnique({
        where: { id: dto.linkedAreaPostId },
      });
      if (!post || post.userId !== userId || post.kind !== AreaPostKind.SHOP) {
        throw new ForbiddenException('linkedAreaPostId must be your own SHOP post');
      }
    }
    return this.prisma.reel.create({
      data: {
        userId,
        videoUrl: dto.videoUrl,
        caption: dto.caption,
        linkedAreaPostId: dto.linkedAreaPostId,
      },
      include: { user: { select: REEL_AUTHOR_SELECT }, linkedPost: { select: LINKED_POST_SELECT } },
    });
  }

  async list(viewerUserId: string | undefined, page: number, pageSize: number) {
    const [items, total] = await Promise.all([
      this.prisma.reel.findMany({
        include: {
          user: { select: REEL_AUTHOR_SELECT },
          linkedPost: { select: LINKED_POST_SELECT },
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

  /** Public, like Instagram's "liked by" list - unlike AreaPostInterest's
   * owner-only viewer list, which gates on real-world contact info (who can
   * help, who to call) rather than on social engagement. */
  async listLikers(reelId: string) {
    const likes = await this.prisma.reelLike.findMany({
      where: { reelId },
      select: { user: { select: REEL_AUTHOR_SELECT }, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
    return likes.map((l) => l.user);
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
