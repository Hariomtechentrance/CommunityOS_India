import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CheckInDto } from './dto/check-in.dto';
import { CreateGoalCommunityDto } from './dto/create-goal-community.dto';
import { GoalCommunitiesService } from './goal-communities.service';

@ApiTags('goal-communities')
@ApiBearerAuth()
@Controller('goal-communities')
@UseGuards(JwtAuthGuard)
export class GoalCommunitiesController {
  constructor(private readonly goalCommunities: GoalCommunitiesService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateGoalCommunityDto) {
    return this.goalCommunities.create(user.userId, dto);
  }

  @Get()
  list(@CurrentUser() user: { userId: string }, @Query('category') category?: string) {
    return this.goalCommunities.list(user.userId, category);
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.goalCommunities.findOne(id, user.userId);
  }

  @Post(':id/join')
  join(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.goalCommunities.join(id, user.userId);
  }

  @Delete(':id/join')
  leave(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.goalCommunities.leave(id, user.userId);
  }

  @Post(':id/check-in')
  checkIn(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CheckInDto,
  ) {
    return this.goalCommunities.checkIn(id, user.userId, dto.note);
  }

  @Get(':id/leaderboard')
  leaderboard(@Param('id') id: string) {
    return this.goalCommunities.leaderboard(id);
  }
}
