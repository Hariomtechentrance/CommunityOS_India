import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { ReportsModule } from '../reports/reports.module';
import { FeedbackModule } from '../feedback/feedback.module';
import { WalletModule } from '../wallet/wallet.module';
import { AdminAuthController } from './admin-auth.controller';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { PlatformAdminGuard } from './guards/platform-admin.guard';

@Module({
  imports: [AuthModule, ReportsModule, FeedbackModule, WalletModule],
  controllers: [AdminAuthController, AdminController],
  providers: [AdminService, PlatformAdminGuard],
})
export class AdminModule {}
