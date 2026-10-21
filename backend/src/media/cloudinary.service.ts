import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

/**
 * Generates short-lived signed-upload credentials for Cloudinary instead of
 * the app shipping a reusable unsigned upload preset - an unsigned preset's
 * cloud name + preset name are both embedded in the APK (not a secret by
 * Cloudinary's own design), so anyone who decompiles the app or sniffs its
 * traffic can use them to upload arbitrary files directly to this account,
 * forever, with no rate limit and no auth. A signature is tied to one
 * specific timestamp and expires with it, so there's nothing reusable to
 * extract.
 */
@Injectable()
export class CloudinaryService {
  private readonly cloudName?: string;
  private readonly apiKey?: string;
  private readonly apiSecret?: string;

  constructor(config: ConfigService) {
    this.cloudName = config.get<string>('CLOUDINARY_CLOUD_NAME');
    this.apiKey = config.get<string>('CLOUDINARY_API_KEY');
    this.apiSecret = config.get<string>('CLOUDINARY_API_SECRET');
  }

  get isConfigured(): boolean {
    return !!this.cloudName && !!this.apiKey && !!this.apiSecret;
  }

  generateSignature() {
    if (!this.cloudName || !this.apiKey || !this.apiSecret) {
      throw new ServiceUnavailableException(
        'Uploads are not configured yet (CLOUDINARY_* env vars missing)',
      );
    }

    const timestamp = Math.floor(Date.now() / 1000);
    // Cloudinary's signing rule: sort every param-to-sign alphabetically by
    // key, join as "key=value&key=value", append the API secret, SHA-1 it.
    // `timestamp` is the only param we send - callers don't get to pick
    // folder/public_id/etc, keeping this endpoint from being a general
    // "sign anything" primitive.
    const toSign = `timestamp=${timestamp}${this.apiSecret}`;
    const signature = crypto.createHash('sha1').update(toSign).digest('hex');

    return {
      cloudName: this.cloudName,
      apiKey: this.apiKey,
      timestamp,
      signature,
    };
  }
}
