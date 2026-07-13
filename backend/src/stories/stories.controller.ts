import { Body, Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { StoryMediaType } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateStoryDto } from './dto/create-story.dto';
import { ReactStoryDto } from './dto/react-story.dto';
import { StoriesService } from './stories.service';

@ApiTags('stories')
@ApiBearerAuth()
@Controller('stories')
@UseGuards(JwtAuthGuard)
export class StoriesController {
  constructor(private readonly stories: StoriesService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateStoryDto) {
    return this.stories.create(
      user.userId,
      dto.mediaUrl,
      dto.mediaType as StoryMediaType,
      dto.audioUrl,
    );
  }

  @Get()
  list(@CurrentUser() user: { userId: string }) {
    return this.stories.listActive(user.userId);
  }

  @Post(':id/view')
  markViewed(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.stories.markViewed(id, user.userId);
  }

  @Get(':id/views')
  getViewers(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.stories.getViewers(id, user.userId);
  }

  @Post(':id/react')
  react(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: ReactStoryDto,
  ) {
    return this.stories.react(id, user.userId, dto.emoji);
  }

  @Delete(':id')
  delete(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.stories.delete(id, user.userId);
  }
}
