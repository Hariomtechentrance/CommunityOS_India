import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { MembershipsService } from '../memberships/memberships.service';
import { CreateSocietyDto } from './dto/create-society.dto';

@Injectable()
export class SocietiesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly memberships: MembershipsService,
  ) {}

  async create(userId: string, dto: CreateSocietyDto) {
    const society = await this.prisma.society.create({ data: dto });
    await this.memberships.createApprovedAdmin(userId, society.id);
    return society;
  }

  async findById(id: string) {
    const society = await this.prisma.society.findUnique({ where: { id } });
    if (!society) throw new NotFoundException('Society not found');
    return society;
  }

  search(query?: string, pincode?: string) {
    return this.prisma.society.findMany({
      where: {
        ...(query ? { name: { contains: query, mode: 'insensitive' } } : {}),
        ...(pincode ? { pincode } : {}),
      },
      take: 20,
    });
  }
}
