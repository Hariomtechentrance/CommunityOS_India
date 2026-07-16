import { Body, Controller, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AdminLoginDto } from './dto/admin-login.dto';
import { AdminService } from './admin.service';

// Deliberately separate from AdminController, which requires an existing
// JwtAuthGuard + PlatformAdminGuard session - this is the public entry point
// that produces that session in the first place.
@ApiTags('admin')
@Controller('admin')
export class AdminAuthController {
  constructor(private readonly admin: AdminService) {}

  @Post('login')
  login(@Body() dto: AdminLoginDto) {
    return this.admin.loginWithPassword(dto.email, dto.password);
  }
}
