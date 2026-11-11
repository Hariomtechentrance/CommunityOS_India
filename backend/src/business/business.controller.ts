import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { BusinessService } from './business.service';
import { SendBroadcastDto } from './dto/send-broadcast.dto';
import { UpsertBusinessProfileDto } from './dto/upsert-business-profile.dto';
import { UpsertCatalogItemDto } from './dto/upsert-catalog-item.dto';

@ApiTags('business')
@ApiBearerAuth()
@Controller('business')
@UseGuards(JwtAuthGuard)
export class BusinessController {
  constructor(private readonly business: BusinessService) {}

  @Post('profile')
  upsertProfile(@CurrentUser() user: { userId: string }, @Body() dto: UpsertBusinessProfileDto) {
    return this.business.upsertProfile(user.userId, dto);
  }

  @Get('profile/me')
  getMyProfile(@CurrentUser() user: { userId: string }) {
    return this.business.getMyProfile(user.userId);
  }

  @Get('profile/:userId')
  getPublicProfile(@Param('userId') userId: string, @CurrentUser() user: { userId: string }) {
    return this.business.getPublicProfile(userId, user.userId);
  }

  @Get(':userId/catalog')
  listCatalog(@Param('userId') userId: string) {
    return this.business.listCatalog(userId);
  }

  @Get('catalog-item/:itemId')
  getCatalogItem(@Param('itemId') itemId: string) {
    return this.business.getCatalogItem(itemId);
  }

  @Post('catalog')
  addCatalogItem(@CurrentUser() user: { userId: string }, @Body() dto: UpsertCatalogItemDto) {
    return this.business.addCatalogItem(user.userId, dto);
  }

  @Patch('catalog/:itemId')
  updateCatalogItem(
    @Param('itemId') itemId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: UpsertCatalogItemDto,
  ) {
    return this.business.updateCatalogItem(user.userId, itemId, dto);
  }

  @Delete('catalog/:itemId')
  deleteCatalogItem(@Param('itemId') itemId: string, @CurrentUser() user: { userId: string }) {
    return this.business.deleteCatalogItem(user.userId, itemId);
  }

  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  @Post('broadcast')
  sendBroadcast(@CurrentUser() user: { userId: string }, @Body() dto: SendBroadcastDto) {
    return this.business.sendBroadcast(user.userId, dto);
  }

  @Get('broadcasts/mine')
  listBroadcasts(@CurrentUser() user: { userId: string }) {
    return this.business.listBroadcasts(user.userId);
  }

  @Get('analytics')
  getAnalytics(@CurrentUser() user: { userId: string }) {
    return this.business.getAnalytics(user.userId);
  }
}
