import { Controller, Get, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

/** Fallback used until METERED_API_KEY is configured - STUN only, no relay,
 * so same-network calls/streams keep working but cross-network ones won't. */
const STUN_ONLY_FALLBACK = [{ urls: 'stun:stun.l.google.com:19302' }];

@ApiTags('turn')
@ApiBearerAuth()
@Controller('turn-credentials')
@UseGuards(JwtAuthGuard)
export class TurnController {
  constructor(private readonly config: ConfigService) {}

  @Get()
  async getCredentials() {
    const apiKey = this.config.get<string>('METERED_API_KEY');
    const appName = this.config.get<string>('METERED_APP_NAME');
    if (!apiKey || !appName) {
      return { iceServers: STUN_ONLY_FALLBACK };
    }

    try {
      const res = await fetch(
        `https://${appName}.metered.live/api/v1/turn/credentials?apiKey=${apiKey}`,
      );
      if (!res.ok) return { iceServers: STUN_ONLY_FALLBACK };
      const iceServers = await res.json();
      return { iceServers };
    } catch {
      return { iceServers: STUN_ONLY_FALLBACK };
    }
  }
}
