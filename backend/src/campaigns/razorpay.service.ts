import { BadGatewayException, Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

export interface RazorpayPaymentLink {
  id: string;
  short_url: string;
}

/**
 * Thin wrapper over Razorpay's REST API - no SDK needed for what we use
 * (Payment Links + webhook signature verification), and this keeps the
 * integration platform-agnostic: the frontend just opens a URL, which works
 * identically on Flutter web and Android (unlike the native-only
 * razorpay_flutter checkout SDK, which doesn't support web at all).
 */
@Injectable()
export class RazorpayService {
  private readonly logger = new Logger(RazorpayService.name);
  private readonly keyId?: string;
  private readonly keySecret?: string;
  private readonly webhookSecret?: string;

  constructor(config: ConfigService) {
    this.keyId = config.get<string>('RAZORPAY_KEY_ID');
    this.keySecret = config.get<string>('RAZORPAY_KEY_SECRET');
    this.webhookSecret = config.get<string>('RAZORPAY_WEBHOOK_SECRET');
  }

  get isConfigured(): boolean {
    return !!this.keyId && !!this.keySecret;
  }

  async createPaymentLink(params: {
    amountInPaise: number;
    description: string;
    referenceId: string;
    callbackUrl: string;
  }): Promise<RazorpayPaymentLink> {
    if (!this.keyId || !this.keySecret) {
      throw new ServiceUnavailableException(
        'Payments are not configured yet (RAZORPAY_KEY_ID/RAZORPAY_KEY_SECRET missing)',
      );
    }

    const auth = Buffer.from(`${this.keyId}:${this.keySecret}`).toString('base64');
    const res = await fetch('https://api.razorpay.com/v1/payment_links', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Basic ${auth}` },
      body: JSON.stringify({
        amount: params.amountInPaise,
        currency: 'INR',
        description: params.description,
        reference_id: params.referenceId,
        callback_url: params.callbackUrl,
        callback_method: 'get',
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      this.logger.error(`Razorpay payment link creation failed: ${res.status} ${body}`);
      throw new BadGatewayException('Failed to create payment link');
    }
    return (await res.json()) as RazorpayPaymentLink;
  }

  /** Verifies a webhook's `X-Razorpay-Signature` header against the exact
   * raw request body - constant-time comparison, and a length mismatch is
   * treated as "not equal" rather than thrown (never trust unverified
   * input into a function that assumes matching buffer lengths). */
  verifyWebhookSignature(rawBody: Buffer, signature: string | undefined): boolean {
    if (!this.webhookSecret || !signature) return false;
    const expected = crypto.createHmac('sha256', this.webhookSecret).update(rawBody).digest('hex');
    const expectedBuf = Buffer.from(expected);
    const actualBuf = Buffer.from(signature);
    if (expectedBuf.length !== actualBuf.length) return false;
    return crypto.timingSafeEqual(expectedBuf, actualBuf);
  }
}
