import { BadRequestException, Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PLACE_CATEGORIES, PlaceCategory, PlacesService } from './places.service';

@ApiTags('places')
@ApiBearerAuth()
@Controller('places')
@UseGuards(JwtAuthGuard)
export class PlacesController {
  constructor(private readonly places: PlacesService) {}

  @Get('nearby')
  nearby(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('category') category: string | undefined,
  ) {
    const parsedLat = parseFloat(lat);
    const parsedLng = parseFloat(lng);
    if (Number.isNaN(parsedLat) || Number.isNaN(parsedLng)) {
      throw new BadRequestException('lat/lng must be valid numbers');
    }
    const resolvedCategory: PlaceCategory = PLACE_CATEGORIES.includes(category as PlaceCategory)
      ? (category as PlaceCategory)
      : 'All';
    return this.places.nearby(parsedLat, parsedLng, resolvedCategory);
  }
}
