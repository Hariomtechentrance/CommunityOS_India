import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SocietyRolesGuard } from '../memberships/guards/society-roles.guard';
import { CreateEventDto } from './dto/create-event.dto';
import { RsvpEventDto } from './dto/rsvp-event.dto';
import { EventsService } from './events.service';

@ApiTags('events')
@ApiBearerAuth()
@Controller('societies/:societyId/events')
@UseGuards(JwtAuthGuard, SocietyRolesGuard)
export class EventsController {
  constructor(private readonly events: EventsService) {}

  @Post()
  create(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateEventDto,
  ) {
    return this.events.create(societyId, user.userId, dto);
  }

  @Get()
  list(@Param('societyId') societyId: string) {
    return this.events.listForSociety(societyId);
  }

  @Get(':eventId')
  findOne(@Param('societyId') societyId: string, @Param('eventId') eventId: string) {
    return this.events.findOne(societyId, eventId);
  }

  @Post(':eventId/rsvp')
  rsvp(
    @Param('societyId') societyId: string,
    @Param('eventId') eventId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: RsvpEventDto,
  ) {
    return this.events.rsvp(societyId, eventId, user.userId, dto.status);
  }
}
