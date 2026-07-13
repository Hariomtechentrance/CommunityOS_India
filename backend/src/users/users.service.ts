import { Injectable } from '@nestjs/common';
import { GeocodingService } from '../geocoding/geocoding.service';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class UsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly geocoding: GeocodingService,
  ) {}

  findByPhone(phone: string) {
    return this.prisma.user.findUnique({ where: { phone } });
  }

  findById(id: string) {
    return this.prisma.user.findUnique({ where: { id } });
  }

  async findOrCreateByPhone(phone: string) {
    const existing = await this.findByPhone(phone);
    if (existing) return existing;
    return this.prisma.user.create({ data: { phone } });
  }

  async updateLocation(userId: string, dto: UpdateLocationDto) {
    let area = dto.area;
    let lat = dto.lat;
    let lng = dto.lng;

    if (lat !== undefined && lng !== undefined && !area) {
      area = (await this.geocoding.reverseGeocode(lat, lng)) ?? undefined;
    } else if (area && (lat === undefined || lng === undefined)) {
      // A bare locality/landmark name (e.g. "Kade Pathar Chowk") is often too
      // hyperlocal for Google to resolve on its own - city/state/pincode give
      // it the context it needs to disambiguate.
      const fullAddress = [area, dto.city, dto.state, dto.pincode, 'India']
        .filter(Boolean)
        .join(', ');
      const point = await this.geocoding.geocode(fullAddress);
      if (point) {
        lat = point.lat;
        lng = point.lng;
      }
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        ...(dto.name !== undefined ? { name: dto.name } : {}),
        ...(dto.addressLine !== undefined ? { addressLine: dto.addressLine } : {}),
        ...(dto.city !== undefined ? { city: dto.city } : {}),
        ...(dto.state !== undefined ? { state: dto.state } : {}),
        ...(dto.pincode !== undefined ? { pincode: dto.pincode } : {}),
        ...(area !== undefined ? { area } : {}),
        ...(lat !== undefined ? { latitude: lat } : {}),
        ...(lng !== undefined ? { longitude: lng } : {}),
      },
    });
  }

  async detectArea(lat: number, lng: number): Promise<{ area: string | null }> {
    const area = await this.geocoding.reverseGeocode(lat, lng);
    return { area };
  }

  listNeighbours(area: string, excludeUserId?: string) {
    return this.prisma.user.findMany({
      where: {
        area: { equals: area, mode: 'insensitive' },
        ...(excludeUserId ? { id: { not: excludeUserId } } : {}),
      },
      select: { id: true, name: true, phone: true, area: true, avatarUrl: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  updateFcmToken(userId: string, token: string) {
    return this.prisma.user.update({ where: { id: userId }, data: { fcmToken: token } });
  }

  updateAvatar(userId: string, avatarUrl: string) {
    return this.prisma.user.update({ where: { id: userId }, data: { avatarUrl } });
  }
}
