import { Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MutesService } from './mutes.service';

@ApiTags('mutes')
@ApiBearerAuth()
@Controller()
@UseGuards(JwtAuthGuard)
export class MutesController {
  constructor(private readonly mutes: MutesService) {}

  @Post('users/:userId/mute')
  mute(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.mutes.mute(currentUser.userId, userId);
  }

  @Delete('users/:userId/mute')
  unmute(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.mutes.unmute(currentUser.userId, userId);
  }

  @Get('users/me/muted')
  listMuted(
    @CurrentUser() currentUser: { userId: string },
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.mutes.listMuted(
      currentUser.userId,
      page ? Number(page) : 1,
      pageSize ? Number(pageSize) : 25,
    );
  }
}
