import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { PostType } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SocietyRolesGuard } from '../memberships/guards/society-roles.guard';
import { CreateCommentDto } from './dto/create-comment.dto';
import { CreatePostDto } from './dto/create-post.dto';
import { PostsService } from './posts.service';

@ApiTags('posts')
@ApiBearerAuth()
@Controller('societies/:societyId/posts')
@UseGuards(JwtAuthGuard, SocietyRolesGuard)
export class PostsController {
  constructor(private readonly posts: PostsService) {}

  @Post()
  create(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreatePostDto,
  ) {
    return this.posts.create(societyId, user.userId, dto);
  }

  @Get()
  list(@Param('societyId') societyId: string, @Query('type') type?: PostType) {
    return this.posts.listForSociety(societyId, type);
  }

  @Get(':postId')
  findOne(@Param('societyId') societyId: string, @Param('postId') postId: string) {
    return this.posts.findOne(societyId, postId);
  }

  @Post(':postId/comments')
  addComment(
    @Param('societyId') societyId: string,
    @Param('postId') postId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateCommentDto,
  ) {
    return this.posts.addComment(societyId, postId, user.userId, dto);
  }
}
