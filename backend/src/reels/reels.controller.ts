import { Body, Controller, Delete, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateReelCommentDto } from './dto/create-reel-comment.dto';
import { CreateReelDto } from './dto/create-reel.dto';
import { ReelsService } from './reels.service';

@ApiTags('reels')
@ApiBearerAuth()
@Controller('reels')
@UseGuards(JwtAuthGuard)
export class ReelsController {
  constructor(private readonly reels: ReelsService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateReelDto) {
    return this.reels.create(user.userId, dto);
  }

  @Get()
  list(
    @CurrentUser() user: { userId: string },
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.reels.list(user.userId, page ? Number(page) : 1, pageSize ? Number(pageSize) : 10);
  }

  @Post(':id/like')
  toggleLike(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.reels.toggleLike(id, user.userId);
  }

  @Get(':id/comments')
  listComments(@Param('id') id: string) {
    return this.reels.listComments(id);
  }

  @Post(':id/comments')
  addComment(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateReelCommentDto,
  ) {
    return this.reels.addComment(id, user.userId, dto.body);
  }

  @Delete(':id')
  delete(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.reels.delete(id, user.userId);
  }
}
