import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { VerifyFirebaseTokenDto } from './dto/verify-firebase-token.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  // Tighter than the global default - this calls Firebase Admin SDK, which
  // has its own quotas, and is the real login path so it's worth guarding
  // against credential-stuffing-style hammering.
  @Throttle({ default: { limit: 20, ttl: 60_000 } })
  @Post('firebase/verify')
  verify(@Body() dto: VerifyFirebaseTokenDto) {
    return this.auth.verifyFirebaseToken(dto.idToken);
  }

  // Unauthenticated by design (public "try it" flow) - throttled hard so it
  // can't be used to mass-create demo users.
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('demo')
  demo() {
    return this.auth.loginAsDemo();
  }

  @Get('demo-users')
  demoUsers() {
    return this.auth.listDemoUsers();
  }

  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  @Post('demo-login/:userId')
  demoLogin(@Param('userId') userId: string) {
    return this.auth.demoLoginAs(userId);
  }
}
