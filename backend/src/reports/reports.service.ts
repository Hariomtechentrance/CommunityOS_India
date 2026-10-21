import { BadRequestException, Injectable } from '@nestjs/common';
import { ReportReason, ReportStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ReportsService {
  constructor(private readonly prisma: PrismaService) {}

  create(
    reporterId: string,
    dto: { userId?: string; postId?: string; reason: ReportReason; details?: string },
  ) {
    if (!dto.userId && !dto.postId) {
      throw new BadRequestException('Either userId or postId must be set');
    }
    if (dto.userId && dto.postId) {
      throw new BadRequestException("Can't report a user and a post in the same report");
    }
    return this.prisma.report.create({
      data: {
        reporterId,
        reportedUserId: dto.userId,
        reportedPostId: dto.postId,
        reason: dto.reason,
        details: dto.details,
      },
    });
  }

  async list(status: ReportStatus | undefined, page: number, pageSize: number) {
    const [items, total] = await Promise.all([
      this.prisma.report.findMany({
        where: status ? { status } : undefined,
        include: {
          reporter: { select: { id: true, name: true, avatarUrl: true } },
          reportedUser: { select: { id: true, name: true, avatarUrl: true } },
          reportedPost: { select: { id: true, title: true, description: true } },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
      this.prisma.report.count({ where: status ? { status } : undefined }),
    ]);
    return { items, total, page, pageSize };
  }

  setStatus(id: string, status: ReportStatus) {
    return this.prisma.report.update({ where: { id }, data: { status } });
  }
}
