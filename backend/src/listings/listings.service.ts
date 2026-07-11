import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ListingCategory, ListingStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateListingDto } from './dto/create-listing.dto';

@Injectable()
export class ListingsService {
  constructor(private readonly prisma: PrismaService) {}

  create(societyId: string, sellerId: string, dto: CreateListingDto) {
    return this.prisma.listing.create({
      data: {
        societyId,
        sellerId,
        category: dto.category as ListingCategory,
        title: dto.title,
        description: dto.description,
        price: dto.price,
        imageUrls: dto.imageUrls ?? [],
      },
    });
  }

  listForSociety(societyId: string, category?: ListingCategory, status?: ListingStatus) {
    return this.prisma.listing.findMany({
      where: {
        societyId,
        status: status ?? ListingStatus.ACTIVE,
        ...(category ? { category } : {}),
      },
      include: { seller: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(societyId: string, listingId: string) {
    const listing = await this.prisma.listing.findUnique({
      where: { id: listingId },
      include: { seller: true },
    });
    if (!listing || listing.societyId !== societyId) {
      throw new NotFoundException('Listing not found');
    }
    return listing;
  }

  async updateStatus(
    societyId: string,
    listingId: string,
    callerUserId: string,
    status: ListingStatus,
  ) {
    const listing = await this.prisma.listing.findUnique({ where: { id: listingId } });
    if (!listing || listing.societyId !== societyId) {
      throw new NotFoundException('Listing not found');
    }
    if (listing.sellerId !== callerUserId) {
      throw new ForbiddenException('Only the seller can update this listing');
    }
    return this.prisma.listing.update({ where: { id: listingId }, data: { status } });
  }
}
