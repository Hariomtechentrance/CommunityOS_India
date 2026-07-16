import { Injectable, NotFoundException } from '@nestjs/common';
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

  /** Anyone's public-facing profile (post authors, followers/following lists,
   * search results) - deliberately excludes phone/email/location precision
   * beyond area, unlike `findById`/`findByPhone` used for the caller's own
   * account. */
  async getPublicProfile(id: string) {
    const user = await this.prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        name: true,
        username: true,
        avatarUrl: true,
        area: true,
        city: true,
        createdAt: true,
      },
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }

  /** Find people by their shareable @username (exact or prefix) or display
   * name - the only way to look someone up without already knowing them
   * (phone numbers are never searchable/shared). */
  async searchUsers(query: string, excludeUserId?: string) {
    const q = query.trim().replace(/^@/, '');
    if (!q) return [];
    return this.prisma.user.findMany({
      where: {
        ...(excludeUserId ? { id: { not: excludeUserId } } : {}),
        OR: [
          { username: { startsWith: q, mode: 'insensitive' } },
          { name: { contains: q, mode: 'insensitive' } },
        ],
      },
      select: { id: true, name: true, username: true, avatarUrl: true, area: true },
      take: 20,
    });
  }

  /** Slugified-name + random suffix, retried on collision - e.g. "Hariom
   * Singh" -> "hariomsingh4821". Falls back to a plain "user" prefix when
   * there's no usable name yet (registration order: phone first, name
   * later via location onboarding). */
  private async generateUsername(name?: string | null): Promise<string> {
    const base =
      (name ?? '')
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '')
        .slice(0, 20) || 'user';

    for (let attempt = 0; attempt < 10; attempt++) {
      const suffix = Math.floor(1000 + Math.random() * 9000);
      const candidate = `${base}${suffix}`;
      const existing = await this.prisma.user.findUnique({ where: { username: candidate } });
      if (!existing) return candidate;
    }
    // Astronomically unlikely to ever reach this, but stay correct rather
    // than silently returning a possibly-colliding handle.
    return `${base}${Date.now()}`;
  }

  async findOrCreateByPhone(phone: string) {
    const existing = await this.findByPhone(phone);
    if (existing) return existing;
    const username = await this.generateUsername();
    return this.prisma.user.create({ data: { phone, username } });
  }

  markLoggedIn(userId: string) {
    return this.prisma.user.update({ where: { id: userId }, data: { lastLoginAt: new Date() } });
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
