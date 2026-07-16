import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminAuthController } from './admin-auth.controller';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { PlatformAdminGuard } from './guards/platform-admin.guard';

@Module({
  imports: [AuthModule],
  controllers: [AdminAuthController, AdminController],
  providers: [AdminService, PlatformAdminGuard],
})
export class AdminModule {}
