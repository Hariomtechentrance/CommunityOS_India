import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ListingCategory, ListingStatus } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { SocietyRolesGuard } from '../memberships/guards/society-roles.guard';
import { CreateListingDto } from './dto/create-listing.dto';
import { UpdateListingStatusDto } from './dto/update-listing-status.dto';
import { ListingsService } from './listings.service';

@ApiTags('listings')
@ApiBearerAuth()
@Controller('societies/:societyId/listings')
@UseGuards(JwtAuthGuard, SocietyRolesGuard)
export class ListingsController {
  constructor(private readonly listings: ListingsService) {}

  @Post()
  create(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateListingDto,
  ) {
    return this.listings.create(societyId, user.userId, dto);
  }

  @Get()
  list(
    @Param('societyId') societyId: string,
    @Query('category') category?: ListingCategory,
    @Query('status') status?: ListingStatus,
  ) {
    return this.listings.listForSociety(societyId, category, status);
  }

  @Get(':listingId')
  findOne(@Param('societyId') societyId: string, @Param('listingId') listingId: string) {
    return this.listings.findOne(societyId, listingId);
  }

  @Patch(':listingId/status')
  updateStatus(
    @Param('societyId') societyId: string,
    @Param('listingId') listingId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateListingStatusDto,
  ) {
    return this.listings.updateStatus(societyId, listingId, user.userId, dto.status as ListingStatus);
  }
}
