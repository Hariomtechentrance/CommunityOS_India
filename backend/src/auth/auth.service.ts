import {
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ListingCategory, MembershipRole, MembershipStatus, PostType } from '@prisma/client';
import type { App } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { PrismaService } from '../prisma/prisma.service';
import { sanitizeUser } from '../users/sanitize-user';
import { UsersService } from '../users/users.service';
import { FIREBASE_ADMIN } from './firebase-admin.provider';

const DEMO_SOCIETY_NAME = 'Demo Society (Preview)';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly users: UsersService,
    private readonly jwt: JwtService,
    @Inject(FIREBASE_ADMIN) private readonly firebaseApp: App | null,
  ) {}

  async verifyFirebaseToken(idToken: string) {
    if (!this.firebaseApp) {
      throw new ServiceUnavailableException(
        'Firebase Admin is not configured yet (set FIREBASE_* env vars)',
      );
    }

    let decoded;
    try {
      decoded = await getAuth(this.firebaseApp).verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Invalid Firebase token');
    }

    const phone = decoded.phone_number;
    if (!phone) {
      throw new UnauthorizedException('Firebase token has no verified phone number');
    }

    const user = await this.users.findOrCreateByPhone(phone);
    if (user.isSuspended) {
      throw new ForbiddenException('This account has been suspended');
    }

    await this.users.markLoggedIn(user.id);
    const accessToken = await this.jwt.signAsync({ sub: user.id, phone: user.phone });

    return { accessToken, user: sanitizeUser({ ...user, lastLoginAt: new Date() }) };
  }

  /**
   * Issues a fresh anonymous demo identity (unique per call, so concurrent
   * visitors don't collide) as Committee Admin of one shared, pre-seeded
   * "Demo Society" - lets every screen/feature be explored end-to-end with
   * real data, with no login/Firebase setup required.
   */
  async loginAsDemo() {
    const society = await this.findOrCreateDemoSociety();

    const demoUser = await this.prisma.user.create({
      data: {
        phone: `+91-demo-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
        name: 'Demo User',
        addressLine: society.addressLine,
        city: society.city,
        state: society.state,
        pincode: society.pincode,
        area: `${society.city} ${society.name}`,
        latitude: 12.9698,
        longitude: 77.75,
      },
    });
    const membership = await this.prisma.membership.create({
      data: {
        userId: demoUser.id,
        societyId: society.id,
        role: MembershipRole.COMMITTEE_ADMIN,
        status: MembershipStatus.APPROVED,
      },
    });

    const accessToken = await this.jwt.signAsync({ sub: demoUser.id, phone: demoUser.phone });
    return { accessToken, user: sanitizeUser(demoUser), society, membership };
  }

  /**
   * Lists demo/seeded identities that already have a location profile, so
   * they can be switched into directly for testing - without needing a fresh
   * "+91-demo-..." identity or a real OTP each time.
   */
  listDemoUsers() {
    return this.prisma.user.findMany({
      where: { phone: { startsWith: '+91-demo-' }, NOT: { name: 'Demo Seed Author' } },
      select: { id: true, name: true, area: true, pincode: true, city: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
      take: 60,
    });
  }

  /** Mints a fresh token for an existing demo identity - same permissive,
   * no-real-auth-required pattern as `loginAsDemo`, just for a known user
   * instead of a brand new one. */
  async demoLoginAs(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');
    const accessToken = await this.jwt.signAsync({ sub: user.id, phone: user.phone });
    return { accessToken, user: sanitizeUser(user) };
  }

  private async findOrCreateDemoSociety() {
    const existing = await this.prisma.society.findFirst({
      where: { name: DEMO_SOCIETY_NAME },
    });
    if (existing) return existing;

    const society = await this.prisma.society.create({
      data: {
        name: DEMO_SOCIETY_NAME,
        addressLine: 'Whitefield Main Road',
        city: 'Bengaluru',
        state: 'Karnataka',
        pincode: '560066',
      },
    });

    const seedAuthor = await this.prisma.user.create({
      data: { phone: `+91-demo-seed-${Date.now()}`, name: 'Demo Seed Author' },
    });
    await this.prisma.membership.create({
      data: {
        userId: seedAuthor.id,
        societyId: society.id,
        role: MembershipRole.COMMITTEE_ADMIN,
        status: MembershipStatus.APPROVED,
      },
    });

    await this.seedDemoContent(society.id, seedAuthor.id);
    return society;
  }

  private async seedDemoContent(societyId: string, authorId: string) {
    await this.prisma.notice.createMany({
      data: [
        {
          societyId,
          authorId,
          title: 'Water supply maintenance on Sunday',
          body: 'Water will be shut off from 10am-2pm for tank cleaning.',
          pinned: true,
        },
        {
          societyId,
          authorId,
          title: 'Diwali celebration this weekend',
          body: 'Join us at the clubhouse for the annual Diwali get-together.',
          pinned: false,
        },
      ],
    });

    await this.prisma.complaint.create({
      data: {
        societyId,
        raisedById: authorId,
        category: 'Plumbing',
        description: 'Leaking pipe under kitchen sink in common area.',
      },
    });

    await this.prisma.post.createMany({
      data: [
        {
          societyId,
          authorId,
          type: PostType.GENERAL,
          title: 'Welcome to the community!',
          body: 'This is a sample post to show how the Community feed works.',
        },
        {
          societyId,
          authorId,
          type: PostType.QUESTION,
          title: 'Any recommendations for a good electrician?',
          body: 'Looking for someone reliable nearby.',
        },
        {
          societyId,
          authorId,
          type: PostType.RECOMMENDATION,
          title: 'Great local bakery',
          body: 'Fresh bread every morning, highly recommend!',
        },
        {
          societyId,
          authorId,
          type: PostType.LOST_FOUND,
          title: 'Found a set of keys near Tower B',
          body: 'Has a red keychain. Contact if it\'s yours.',
        },
      ],
    });

    await this.prisma.poll.create({
      data: {
        societyId,
        authorId,
        question: 'Any cricket this Sunday?',
        options: { create: [{ label: 'Yes, 7am' }, { label: 'Yes, 5pm' }, { label: 'No' }] },
      },
    });

    await this.prisma.event.create({
      data: {
        societyId,
        authorId,
        title: 'Sunday Morning Cricket',
        description: 'Friendly match, all skill levels welcome.',
        location: 'Society clubhouse ground',
        startAt: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
      },
    });

    await this.prisma.listing.create({
      data: {
        societyId,
        sellerId: authorId,
        category: ListingCategory.ITEM_SALE,
        title: 'Study table, barely used',
        description: 'Wooden study table, 3ft x 2ft, no scratches.',
        price: 1500,
        imageUrls: [],
      },
    });
  }
}
