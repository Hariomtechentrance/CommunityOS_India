import { Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { BlocksService } from './blocks.service';

@ApiTags('blocks')
@ApiBearerAuth()
@Controller()
@UseGuards(JwtAuthGuard)
export class BlocksController {
  constructor(private readonly blocks: BlocksService) {}

  @Post('users/:userId/block')
  block(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.blocks.block(currentUser.userId, userId);
  }

  @Delete('users/:userId/block')
  unblock(
    @Param('userId') userId: string,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.blocks.unblock(currentUser.userId, userId);
  }

  @Get('users/me/blocked')
  listBlocked(
    @CurrentUser() currentUser: { userId: string },
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.blocks.listBlocked(
      currentUser.userId,
      page ? Number(page) : 1,
      pageSize ? Number(pageSize) : 25,
    );
  }
}
