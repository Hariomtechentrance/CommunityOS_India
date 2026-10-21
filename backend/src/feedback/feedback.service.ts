import { Injectable } from '@nestjs/common';
import { FeedbackCategory, FeedbackStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FeedbackService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, dto: { category: FeedbackCategory; message: string; rating?: number }) {
    return this.prisma.feedback.create({
      data: { userId, category: dto.category, message: dto.message, rating: dto.rating },
    });
  }

  async list(
    category: FeedbackCategory | undefined,
    status: FeedbackStatus | undefined,
    page: number,
    pageSize: number,
  ) {
    const where = { ...(category ? { category } : {}), ...(status ? { status } : {}) };
    const [items, total] = await Promise.all([
      this.prisma.feedback.findMany({
        where,
        include: { user: { select: { id: true, name: true, avatarUrl: true, phone: true } } },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.feedback.count({ where }),
    ]);
    return { items, total, page, pageSize };
  }

  setStatus(id: string, status: FeedbackStatus) {
    return this.prisma.feedback.update({ where: { id }, data: { status } });
  }
}
