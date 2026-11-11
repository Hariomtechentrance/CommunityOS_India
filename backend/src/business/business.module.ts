import { Module } from '@nestjs/common';
import { FollowsModule } from '../follows/follows.module';
import { BusinessController } from './business.controller';
import { BusinessService } from './business.service';

@Module({
  imports: [FollowsModule],
  controllers: [BusinessController],
  providers: [BusinessService],
})
export class BusinessModule {}
