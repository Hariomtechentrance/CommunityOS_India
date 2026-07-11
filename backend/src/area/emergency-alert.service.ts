import { Inject, Injectable, Logger } from '@nestjs/common';
import type { AreaPost } from '@prisma/client';
import type { App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import { FIREBASE_ADMIN } from '../auth/firebase-admin.provider';
import { PrismaService } from '../prisma/prisma.service';
import { AlertsGateway } from './alerts.gateway';

/**
 * Fans an EMERGENCY_SOS post out to everyone in the author's pincode, two
 * ways: an instant real-time alert (for anyone with the app open) and a
 * push notification (for anyone who granted notification permission, even
 * with the app closed). There is deliberately no way to reach someone who
 * has denied notification permission entirely - no app can override that.
 */
@Injectable()
export class EmergencyAlertService {
  private readonly logger = new Logger(EmergencyAlertService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly alertsGateway: AlertsGateway,
    @Inject(FIREBASE_ADMIN) private readonly firebaseApp: App | null,
  ) {}

  async notifyNearby(post: AreaPost, authorId: string) {
    const author = await this.prisma.user.findUnique({ where: { id: authorId } });
    if (!author?.pincode) {
      this.logger.warn(`SOS post ${post.id}: author has no pincode, skipping alert fan-out`);
      return;
    }

    const nearby = await this.prisma.user.findMany({
      where: { pincode: author.pincode, id: { not: authorId } },
      select: { id: true, fcmToken: true },
    });
    if (nearby.length === 0) return;

    const payload = {
      postId: post.id,
      title: post.title,
      description: post.description,
      emergencyCategory: post.emergencyCategory,
      area: post.area,
    };

    this.alertsGateway.pushToUsers(
      nearby.map((u) => u.id),
      payload,
    );

    if (!this.firebaseApp) return;
    const messaging = getMessaging(this.firebaseApp);
    for (const user of nearby) {
      if (!user.fcmToken) continue;
      try {
        await messaging.send({
          token: user.fcmToken,
          notification: {
            title: `Emergency near you: ${post.emergencyCategory ?? 'SOS'}`,
            body: post.title,
          },
          data: { postId: post.id },
        });
      } catch (error) {
        this.logger.warn(`Push to user ${user.id} failed (stale token?): ${error}`);
      }
    }
  }
}
