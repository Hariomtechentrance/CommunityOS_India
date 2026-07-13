import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { StoryMediaType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const STORY_LIFETIME_MS = 24 * 60 * 60 * 1000;

@Injectable()
export class StoriesService {
  constructor(private readonly prisma: PrismaService) {}

  async create(userId: string, mediaUrl: string, mediaType: StoryMediaType) {
    const author = await this.prisma.user.findUnique({ where: { id: userId } });
    return this.prisma.story.create({
      data: {
        userId,
        mediaUrl,
        mediaType,
        area: author?.area ?? '',
        expiresAt: new Date(Date.now() + STORY_LIFETIME_MS),
      },
    });
  }

  /** Flat list, newest first - the frontend groups these by author. */
  async listActive(viewerUserId: string) {
    const viewer = await this.prisma.user.findUnique({ where: { id: viewerUserId } });
    if (!viewer?.area) return [];

    const stories = await this.prisma.story.findMany({
      where: { area: { equals: viewer.area, mode: 'insensitive' }, expiresAt: { gt: new Date() } },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true } },
        views: { where: { viewerId: viewerUserId } },
      },
      orderBy: { createdAt: 'asc' },
    });

    return stories.map((story) => ({
      ...story,
      seenByMe: story.views.length > 0,
      views: undefined,
    }));
  }

  async markViewed(storyId: string, viewerId: string) {
    await this.prisma.storyView.upsert({
      where: { storyId_viewerId: { storyId, viewerId } },
      create: { storyId, viewerId },
      update: {},
    });
    return { viewed: true };
  }

  async delete(storyId: string, userId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Story not found');
    if (story.userId !== userId) throw new ForbiddenException('Not your story');
    await this.prisma.story.delete({ where: { id: storyId } });
    return { deleted: true };
  }
}
