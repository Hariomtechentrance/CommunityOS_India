import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { CampaignsController } from './campaigns.controller';
import { CampaignsService } from './campaigns.service';
import { RazorpayService } from './razorpay.service';

@Module({
  imports: [UsersModule],
  controllers: [CampaignsController],
  providers: [CampaignsService, RazorpayService],
})
export class CampaignsModule {}
