import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AreaPostKind } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AreaService } from './area.service';
import { CreateAreaPostCommentDto } from './dto/create-area-post-comment.dto';
import { CreateAreaPostDto } from './dto/create-area-post.dto';

@ApiTags('area')
@ApiBearerAuth()
@Controller('area-posts')
@UseGuards(JwtAuthGuard)
export class AreaPostsController {
  constructor(private readonly area: AreaService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateAreaPostDto) {
    return this.area.createAreaPost(user.userId, dto);
  }

  @Get()
  list(
    @Query('area') area: string,
    @Query('kind') kind: AreaPostKind | undefined,
    @Query('mine') mine: string | undefined,
    @CurrentUser() user: { userId: string },
  ) {
    return this.area.listForArea(area, kind, user.userId, mine === 'true');
  }

  // Must be registered before ':id' so these aren't swallowed as an :id param.
  @Get('saved')
  listSaved(@CurrentUser() user: { userId: string }) {
    return this.area.listSaved(user.userId);
  }

  @Get('nearby')
  nearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('radiusKm') radiusKm: string | undefined,
    @Query('kind') kind: AreaPostKind | undefined,
    @CurrentUser() user: { userId: string },
  ) {
    return this.area.listNearby(
      parseFloat(lat),
      parseFloat(lng),
      radiusKm ? parseFloat(radiusKm) : 10,
      kind,
      user.userId,
    );
  }

  @Get(':id')
  findOne(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.area.findOne(id, user.userId);
  }

  @Post(':id/interest')
  toggleInterest(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.area.toggleInterest(id, user.userId);
  }

  @Post(':id/save')
  toggleSave(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.area.toggleSave(id, user.userId);
  }

  @Get(':id/comments')
  listComments(@Param('id') id: string) {
    return this.area.listComments(id);
  }

  @Post(':id/comments')
  addComment(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateAreaPostCommentDto,
  ) {
    return this.area.addComment(id, user.userId, dto.body);
  }
}
