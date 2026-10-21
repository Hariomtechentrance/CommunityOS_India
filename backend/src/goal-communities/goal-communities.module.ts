import { Module } from '@nestjs/common';
import { WalletModule } from '../wallet/wallet.module';
import { GoalCommunitiesController } from './goal-communities.controller';
import { GoalCommunitiesService } from './goal-communities.service';

@Module({
  imports: [WalletModule],
  controllers: [GoalCommunitiesController],
  providers: [GoalCommunitiesService],
})
export class GoalCommunitiesModule {}
