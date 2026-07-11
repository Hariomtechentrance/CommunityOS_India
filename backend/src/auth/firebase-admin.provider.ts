import { Logger, Provider } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { cert, getApps, initializeApp, type App } from 'firebase-admin/app';

export const FIREBASE_ADMIN = 'FIREBASE_ADMIN';

const logger = new Logger('FirebaseAdmin');

/**
 * Returns null (rather than throwing) when Firebase credentials aren't
 * configured yet, so the rest of the API keeps working before Firebase setup
 * is complete - only the /auth/firebase/verify endpoint depends on this.
 */
export const firebaseAdminProvider: Provider = {
  provide: FIREBASE_ADMIN,
  inject: [ConfigService],
  useFactory: (config: ConfigService): App | null => {
    const existing = getApps();
    if (existing.length) {
      return existing[0];
    }

    try {
      return initializeApp({
        credential: cert({
          projectId: config.get<string>('FIREBASE_PROJECT_ID'),
          clientEmail: config.get<string>('FIREBASE_CLIENT_EMAIL'),
          privateKey: config.get<string>('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
        }),
      });
    } catch {
      logger.warn(
        'Firebase Admin not initialized (missing/invalid FIREBASE_* env vars). ' +
          'Phone login will fail until these are set - everything else still works.',
      );
      return null;
    }
  },
};
