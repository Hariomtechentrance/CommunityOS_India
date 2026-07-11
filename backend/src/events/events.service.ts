import { Injectable, NotFoundException } from '@nestjs/common';
import { RsvpStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateEventDto } from './dto/create-event.dto';

@Injectable()
export class EventsService {
  constructor(private readonly prisma: PrismaService) {}

  create(societyId: string, authorId: string, dto: CreateEventDto) {
    return this.prisma.event.create({
      data: {
        societyId,
        authorId,
        title: dto.title,
        description: dto.description,
        location: dto.location,
        startAt: new Date(dto.startAt),
      },
    });
  }

  listForSociety(societyId: string) {
    return this.prisma.event.findMany({
      where: { societyId },
      include: { author: true, rsvps: true },
      orderBy: { startAt: 'asc' },
    });
  }

  async findOne(societyId: string, eventId: string) {
    const event = await this.prisma.event.findUnique({
      where: { id: eventId },
      include: { author: true, rsvps: { include: { user: true } } },
    });
    if (!event || event.societyId !== societyId) {
      throw new NotFoundException('Event not found');
    }
    return event;
  }

  async rsvp(societyId: string, eventId: string, userId: string, status: RsvpStatus) {
    const event = await this.prisma.event.findUnique({ where: { id: eventId } });
    if (!event || event.societyId !== societyId) {
      throw new NotFoundException('Event not found');
    }
    return this.prisma.eventRsvp.upsert({
      where: { eventId_userId: { eventId, userId } },
      update: { status },
      create: { eventId, userId, status },
    });
  }
}
