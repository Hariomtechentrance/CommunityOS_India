import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../prisma/prisma.service';

export interface JwtPayload {
  sub: string;
  phone: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly logger = new Logger(JwtStrategy.name);

  constructor(
    config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_SECRET')!,
    });
  }

  /** Re-checked on every request (not just at login) so a super-admin
   * suspending a user takes effect immediately, instead of waiting out the
   * token's full 30-day lifetime. A *definitive* answer (user missing or
   * flagged suspended) rejects the request - but a DB error here (this
   * project's Neon instance has a known history of transient connection
   * blips) must NOT be treated the same way, or a brief infra hiccup would
   * force-logout every active user on their next request. Fail open on
   * ambiguous DB errors; only fail closed on a definitive answer. */
  async validate(payload: JwtPayload) {
    let user: { isSuspended: boolean } | null;
    try {
      user = await this.prisma.user.findUnique({
        where: { id: payload.sub },
        select: { isSuspended: true },
      });
    } catch (error) {
      this.logger.warn(`Suspend-check DB query failed, allowing request through: ${error}`);
      return { userId: payload.sub, phone: payload.phone };
    }
    if (!user || user.isSuspended) {
      throw new UnauthorizedException('Account not found or suspended');
    }
    return { userId: payload.sub, phone: payload.phone };
  }
}
