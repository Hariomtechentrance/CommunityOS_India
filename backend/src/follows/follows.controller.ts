import { Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UsersService } from '../users/users.service';
import { FollowsService } from './follows.service';

@ApiTags('follows')
@ApiBearerAuth()
@Controller('users/:userId')
@UseGuards(JwtAuthGuard)
export class FollowsController {
  constructor(
    private readonly follows: FollowsService,
    private readonly users: UsersService,
  ) {}

  @Get('profile')
  getProfile(@Param('userId') userId: string) {
    return this.users.getPublicProfile(userId);
  }

  @Post('follow')
  follow(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.follows.follow(currentUser.userId, userId);
  }

  @Delete('follow')
  unfollow(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.follows.unfollow(currentUser.userId, userId);
  }

  @Get('follow-stats')
  getStats(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.follows.getStats(userId, currentUser.userId);
  }

  @Get('followers')
  listFollowers(
    @Param('userId') userId: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.follows.listFollowers(userId, page ? Number(page) : 1, pageSize ? Number(pageSize) : 25);
  }

  @Get('following')
  listFollowing(
    @Param('userId') userId: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.follows.listFollowing(userId, page ? Number(page) : 1, pageSize ? Number(pageSize) : 25);
  }
}
