import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PostType } from '@prisma/client';
import { CreatePostDto } from './dto/create-post.dto';
import { CreateCommentDto } from './dto/create-comment.dto';

@Injectable()
export class PostsService {
  constructor(private readonly prisma: PrismaService) {}

  create(societyId: string, authorId: string, dto: CreatePostDto) {
    return this.prisma.post.create({
      data: {
        societyId,
        authorId,
        type: (dto.type as PostType) ?? PostType.GENERAL,
        title: dto.title,
        body: dto.body,
      },
    });
  }

  listForSociety(societyId: string, type?: PostType) {
    return this.prisma.post.findMany({
      where: { societyId, ...(type ? { type } : {}) },
      include: { author: true, _count: { select: { comments: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(societyId: string, postId: string) {
    const post = await this.prisma.post.findUnique({
      where: { id: postId },
      include: {
        author: true,
        comments: { include: { author: true }, orderBy: { createdAt: 'asc' } },
      },
    });
    if (!post || post.societyId !== societyId) {
      throw new NotFoundException('Post not found');
    }
    return post;
  }

  async addComment(societyId: string, postId: string, authorId: string, dto: CreateCommentDto) {
    const post = await this.prisma.post.findUnique({ where: { id: postId } });
    if (!post || post.societyId !== societyId) {
      throw new NotFoundException('Post not found');
    }
    return this.prisma.comment.create({
      data: { postId, authorId, body: dto.body },
      include: { author: true },
    });
  }
}
