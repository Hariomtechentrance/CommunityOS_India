import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ProjectsService {
  constructor(private readonly prisma: PrismaService) {}

  create(userId: string, dto: { name: string; description: string; category?: string }) {
    return this.prisma.project.create({ data: { userId, ...dto } });
  }

  listForUser(userId: string) {
    return this.prisma.project.findMany({
      where: { userId },
      include: { _count: { select: { updates: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const project = await this.prisma.project.findUnique({
      where: { id },
      include: {
        user: { select: { id: true, name: true, avatarUrl: true } },
        updates: { orderBy: { createdAt: 'desc' } },
      },
    });
    if (!project) throw new NotFoundException('Project not found');
    return project;
  }

  async addUpdate(
    projectId: string,
    userId: string,
    dto: { dayNumber?: number; body: string; imageUrl?: string },
  ) {
    const project = await this.prisma.project.findUnique({ where: { id: projectId } });
    if (!project) throw new NotFoundException('Project not found');
    if (project.userId !== userId) throw new ForbiddenException('Not your project');
    return this.prisma.projectUpdate.create({ data: { projectId, ...dto } });
  }

  async delete(id: string, userId: string) {
    const project = await this.prisma.project.findUnique({ where: { id } });
    if (!project) throw new NotFoundException('Project not found');
    if (project.userId !== userId) throw new ForbiddenException('Not your project');
    await this.prisma.project.delete({ where: { id } });
    return { success: true };
  }
}
