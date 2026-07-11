import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateComplaintDto } from './dto/create-complaint.dto';

@Injectable()
export class ComplaintsService {
  constructor(private readonly prisma: PrismaService) {}

  create(societyId: string, raisedById: string, dto: CreateComplaintDto) {
    return this.prisma.complaint.create({
      data: { societyId, raisedById, ...dto },
    });
  }

  listForSociety(societyId: string, onlyOwnedBy?: string) {
    return this.prisma.complaint.findMany({
      where: { societyId, ...(onlyOwnedBy ? { raisedById: onlyOwnedBy } : {}) },
      include: { raisedBy: true, unit: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateStatus(
    societyId: string,
    complaintId: string,
    status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED',
  ) {
    const complaint = await this.prisma.complaint.findUnique({ where: { id: complaintId } });
    if (!complaint || complaint.societyId !== societyId) {
      throw new NotFoundException('Complaint not found');
    }
    return this.prisma.complaint.update({ where: { id: complaintId }, data: { status } });
  }
}
