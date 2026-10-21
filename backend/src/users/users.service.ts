import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import type { MessagePrivacy } from '@prisma/client';
import type { App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { BlocksService } from '../blocks/blocks.service';
import { FIREBASE_ADMIN } from '../auth/firebase-admin.provider';
import { GeocodingService } from '../geocoding/geocoding.service';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly geocoding: GeocodingService,
    private readonly blocks: BlocksService,
    @Inject(FIREBASE_ADMIN) private readonly firebaseApp: App | null,
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
        headline: true,
        skills: true,
        availableFor: true,
        hideLikeCounts: true,
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
          { headline: { contains: q, mode: 'insensitive' } },
          { skills: { has: q } },
        ],
      },
      select: {
        id: true,
        name: true,
        username: true,
        avatarUrl: true,
        area: true,
        headline: true,
        skills: true,
      },
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

  /** Records that this user's device was physically at (lat, lng) right now,
   * for the travel feed (see LocationVisit in schema.prisma) - upserts on
   * (userId, pincode) so revisiting the same city just refreshes lastSeenAt
   * rather than piling up duplicate rows. Silently no-ops if reverse
   * geocoding can't resolve a pincode, same best-effort spirit as push
   * registration - this must never fail the caller's app-open flow. */
  async recordLocationVisit(userId: string, lat: number, lng: number) {
    const { pincode, area, city } = await this.geocoding.reverseGeocodeDetailed(lat, lng);
    if (!pincode) return null;

    return this.prisma.locationVisit.upsert({
      where: { userId_pincode: { userId, pincode } },
      update: { lastSeenAt: new Date(), area, city, latitude: lat, longitude: lng },
      create: { userId, pincode, area, city, latitude: lat, longitude: lng },
    });
  }

  async listNeighbours(area: string, excludeUserId?: string) {
    const blockedIds = excludeUserId ? await this.blocks.blockedUserIds(excludeUserId) : [];
    return this.prisma.user.findMany({
      where: {
        area: { equals: area, mode: 'insensitive' },
        ...(excludeUserId ? { id: { notIn: [excludeUserId, ...blockedIds] } } : {}),
      },
      select: { id: true, name: true, phone: true, area: true, avatarUrl: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  updateNotificationSettings(
    userId: string,
    data: {
      activityNotificationsEnabled?: boolean;
      hideLikeCounts?: boolean;
      allowMessagesFrom?: MessagePrivacy;
    },
  ) {
    return this.prisma.user.update({ where: { id: userId }, data });
  }

  updateProfessionalProfile(
    userId: string,
    data: { headline?: string; skills?: string[]; availableFor?: string[] },
  ) {
    return this.prisma.user.update({ where: { id: userId }, data });
  }

  updateFcmToken(userId: string, token: string) {
    return this.prisma.user.update({ where: { id: userId }, data: { fcmToken: token } });
  }

  updateAvatar(userId: string, avatarUrl: string) {
    return this.prisma.user.update({ where: { id: userId }, data: { avatarUrl } });
  }

  /** Self-service account deletion - required by Play Store policy for any
   * app that allows account creation. Removes the Firebase phone-auth
   * identity too (best-effort - a lookup/delete failure there shouldn't
   * block the user from deleting their own app data), then deletes the
   * Prisma User row, which cascades to every owned relation across the
   * schema (posts, messages, wallet, memberships, etc. all have
   * onDelete: Cascade back to User). */
  async deleteOwnAccount(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    if (this.firebaseApp) {
      try {
        const firebaseUser = await getAuth(this.firebaseApp).getUserByPhoneNumber(user.phone);
        await getAuth(this.firebaseApp).deleteUser(firebaseUser.uid);
      } catch (err) {
        this.logger.warn(`Firebase account cleanup failed for user ${userId}: ${err}`);
      }
    }

    await this.prisma.user.delete({ where: { id: userId } });
    return { success: true };
  }
}
