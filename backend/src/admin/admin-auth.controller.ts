import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AdminLoginDto } from './dto/admin-login.dto';
import { AdminService } from './admin.service';

// Deliberately separate from AdminController, which requires an existing
// JwtAuthGuard + PlatformAdminGuard session - this is the public entry point
// that produces that session in the first place.
@ApiTags('admin')
@Controller('admin')
export class AdminAuthController {
  constructor(private readonly admin: AdminService) {}

  // This is a password login for the platform's highest-privilege account -
  // worth guarding against brute force specifically, tighter than the
  // global default and tighter than the consumer OTP login (that one's
  // already gated by Firebase's own SMS-based rate limiting; a bare
  // email+password form has no such built-in protection).
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  @Post('login')
  login(@Body() dto: AdminLoginDto) {
    return this.admin.loginWithPassword(dto.email, dto.password);
  }
}
