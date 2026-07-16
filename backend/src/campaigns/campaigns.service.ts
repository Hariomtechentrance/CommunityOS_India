import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { CampaignStatus, CampaignTargetType, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCampaignDto } from './dto/create-campaign.dto';
import { RazorpayService } from './razorpay.service';

const EARTH_RADIUS_KM = 6371;

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

@Injectable()
export class CampaignsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly razorpay: RazorpayService,
    private readonly config: ConfigService,
  ) {}

  create(userId: string, dto: CreateCampaignDto) {
    return this.prisma.campaign.create({
      data: {
        userId,
        objective: dto.objective as any,
        title: dto.title,
        description: dto.description,
        imageUrl: dto.imageUrl,
        ctaUrl: dto.ctaUrl,
        targetType: dto.targetType as any,
        targetPincode: dto.targetPincode,
        targetStates: dto.targetStates ?? [],
        targetLatitude: dto.targetLatitude,
        targetLongitude: dto.targetLongitude,
        targetRadiusKm: dto.targetRadiusKm,
        budgetInPaise: dto.budgetInPaise,
      },
    });
  }

  listMine(userId: string) {
    return this.prisma.campaign.findMany({
      where: { userId },
      include: { payments: { orderBy: { createdAt: 'desc' }, take: 1 } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async checkout(campaignId: string, userId: string) {
    const campaign = await this.prisma.campaign.findUnique({ where: { id: campaignId } });
    if (!campaign) throw new NotFoundException('Campaign not found');
    if (campaign.userId !== userId) throw new ForbiddenException('Not your campaign');
    if (campaign.status === CampaignStatus.ACTIVE || campaign.status === CampaignStatus.COMPLETED) {
      throw new ForbiddenException(`Campaign is already ${campaign.status.toLowerCase()}`);
    }

    const appUrl = this.config.get<string>('APP_URL') ?? 'https://community-os-india.web.app';
    const link = await this.razorpay.createPaymentLink({
      amountInPaise: campaign.budgetInPaise,
      description: `NIKAT ad campaign: ${campaign.title}`,
      referenceId: campaign.id,
      callbackUrl: `${appUrl}/#/home/ads/mine`,
    });

    await this.prisma.campaignPayment.create({
      data: {
        campaignId: campaign.id,
        razorpayLinkId: link.id,
        amountInPaise: campaign.budgetInPaise,
      },
    });
    await this.prisma.campaign.update({
      where: { id: campaign.id },
      data: { status: CampaignStatus.PENDING_PAYMENT },
    });

    return { checkoutUrl: link.short_url };
  }

  /** Razorpay calls this directly - no user session, verified purely by the
   * webhook's HMAC signature over the raw body. */
  async handleWebhook(rawBody: Buffer, signature: string | undefined) {
    if (!this.razorpay.verifyWebhookSignature(rawBody, signature)) {
      throw new ForbiddenException('Invalid webhook signature');
    }

    const payload = JSON.parse(rawBody.toString('utf8'));
    if (payload.event !== 'payment_link.paid') return { received: true };

    const linkId = payload.payload?.payment_link?.entity?.id as string | undefined;
    const paymentId = payload.payload?.payment?.entity?.id as string | undefined;
    if (!linkId) return { received: true };

    const payment = await this.prisma.campaignPayment.findUnique({
      where: { razorpayLinkId: linkId },
    });
    if (!payment) return { received: true };

    await this.prisma.campaignPayment.update({
      where: { id: payment.id },
      data: { status: 'paid', razorpayPaymentId: paymentId },
    });
    await this.prisma.campaign.update({
      where: { id: payment.campaignId },
      data: { status: CampaignStatus.ACTIVE, startDate: new Date() },
    });
    return { received: true };
  }

  /** Active campaigns matching this viewer's location - mirrors
   * AreaService's reach logic (pincode / radius / states / all-India). */
  async feedFor(viewer: {
    pincode: string | null | undefined;
    state: string | null | undefined;
    latitude: number | null | undefined;
    longitude: number | null | undefined;
  }) {
    const clauses: Prisma.CampaignWhereInput[] = [{ targetType: CampaignTargetType.ALL_INDIA }];
    if (viewer.pincode) {
      clauses.push({ targetType: CampaignTargetType.PINCODE, targetPincode: viewer.pincode });
    }
    if (viewer.state) {
      clauses.push({ targetType: CampaignTargetType.STATES, targetStates: { has: viewer.state } });
    }
    if (viewer.latitude != null && viewer.longitude != null) {
      // Can't compute exact haversine distance in SQL - pull in every
      // NEARBY campaign within a generous bounding box, then filter exactly
      // in JS below (same two-stage pattern as AreaService).
      const maxDelta = 25 / 111;
      clauses.push({
        targetType: CampaignTargetType.NEARBY,
        targetLatitude: { gte: viewer.latitude - maxDelta, lte: viewer.latitude + maxDelta },
        targetLongitude: { gte: viewer.longitude - maxDelta, lte: viewer.longitude + maxDelta },
      });
    }

    const campaigns = await this.prisma.campaign.findMany({
      where: { status: CampaignStatus.ACTIVE, OR: clauses },
      include: { user: { select: { id: true, name: true, avatarUrl: true } } },
      orderBy: { createdAt: 'desc' },
      take: 10,
    });

    return campaigns.filter((c) => {
      if (c.targetType !== CampaignTargetType.NEARBY) return true;
      if (c.targetLatitude == null || c.targetLongitude == null || c.targetRadiusKm == null) {
        return false;
      }
      if (viewer.latitude == null || viewer.longitude == null) return false;
      return (
        haversineKm(c.targetLatitude, c.targetLongitude, viewer.latitude, viewer.longitude) <=
        c.targetRadiusKm
      );
    });
  }
}
