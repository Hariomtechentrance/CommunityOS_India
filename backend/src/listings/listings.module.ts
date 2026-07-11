import { Module } from '@nestjs/common';
import { MembershipsModule } from '../memberships/memberships.module';
import { ListingsController } from './listings.controller';
import { ListingsService } from './listings.service';

@Module({
  imports: [MembershipsModule],
  controllers: [ListingsController],
  providers: [ListingsService],
})
export class ListingsModule {}
