import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestMembershipDto } from './dto/request-membership.dto';
import { MembershipRole, MembershipStatus } from './common/roles.enum';

@Injectable()
export class MembershipsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Used when a society is first created - the creator becomes its admin immediately. */
  async createApprovedAdmin(userId: string, societyId: string) {
    return this.prisma.membership.create({
      data: {
        userId,
        societyId,
        role: MembershipRole.COMMITTEE_ADMIN,
        status: MembershipStatus.APPROVED,
      },
    });
  }

  async requestToJoin(userId: string, societyId: string, dto: RequestMembershipDto) {
    const society = await this.prisma.society.findUnique({ where: { id: societyId } });
    if (!society) throw new NotFoundException('Society not found');

    const existing = await this.prisma.membership.findUnique({
      where: { userId_societyId: { userId, societyId } },
    });
    if (existing) {
      throw new ConflictException('Membership request already exists for this society');
    }

    let unitId: string | undefined;
    if (dto.unitNumber) {
      const unit = await this.prisma.unit.upsert({
        where: { societyId_unitNumber: { societyId, unitNumber: dto.unitNumber } },
        update: {},
        create: { societyId, unitNumber: dto.unitNumber, blockName: dto.blockName },
      });
      unitId = unit.id;
    }

    return this.prisma.membership.create({
      data: {
        userId,
        societyId,
        unitId,
        role: MembershipRole.RESIDENT,
        status: MembershipStatus.PENDING,
      },
    });
  }

  findMine(userId: string, societyId: string) {
    return this.prisma.membership.findUnique({
      where: { userId_societyId: { userId, societyId } },
      include: { unit: true },
    });
  }

  listForSociety(societyId: string, status?: MembershipStatus) {
    return this.prisma.membership.findMany({
      where: { societyId, ...(status ? { status } : {}) },
      include: { user: true, unit: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateStatus(societyId: string, membershipId: string, status: 'APPROVED' | 'REJECTED') {
    const membership = await this.prisma.membership.findUnique({ where: { id: membershipId } });
    if (!membership || membership.societyId !== societyId) {
      throw new NotFoundException('Membership not found');
    }
    return this.prisma.membership.update({
      where: { id: membershipId },
      data: { status },
    });
  }
}
