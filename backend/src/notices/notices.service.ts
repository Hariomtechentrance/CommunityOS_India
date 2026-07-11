import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateNoticeDto } from './dto/create-notice.dto';

@Injectable()
export class NoticesService {
  constructor(private readonly prisma: PrismaService) {}

  create(societyId: string, authorId: string, dto: CreateNoticeDto) {
    return this.prisma.notice.create({
      data: { societyId, authorId, ...dto },
    });
  }

  listForSociety(societyId: string) {
    return this.prisma.notice.findMany({
      where: { societyId },
      include: { author: true },
      orderBy: [{ pinned: 'desc' }, { createdAt: 'desc' }],
    });
  }
}
