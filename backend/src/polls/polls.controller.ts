import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SocietyRolesGuard } from '../memberships/guards/society-roles.guard';
import { CreatePollDto } from './dto/create-poll.dto';
import { VotePollDto } from './dto/vote-poll.dto';
import { PollsService } from './polls.service';

@ApiTags('polls')
@ApiBearerAuth()
@Controller('societies/:societyId/polls')
@UseGuards(JwtAuthGuard, SocietyRolesGuard)
export class PollsController {
  constructor(private readonly polls: PollsService) {}

  @Post()
  create(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreatePollDto,
  ) {
    return this.polls.create(societyId, user.userId, dto);
  }

  @Get()
  list(@Param('societyId') societyId: string, @CurrentUser() user: { userId: string }) {
    return this.polls.listForSociety(societyId, user.userId);
  }

  @Post(':pollId/vote')
  vote(
    @Param('societyId') societyId: string,
    @Param('pollId') pollId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: VotePollDto,
  ) {
    return this.polls.vote(societyId, pollId, user.userId, dto.optionId);
  }
}
