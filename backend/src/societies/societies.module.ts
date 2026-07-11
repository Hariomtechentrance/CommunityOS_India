import { Module } from '@nestjs/common';
import { MembershipsModule } from '../memberships/memberships.module';
import { SocietiesController } from './societies.controller';
import { SocietiesService } from './societies.service';

@Module({
  imports: [MembershipsModule],
  controllers: [SocietiesController],
  providers: [SocietiesService],
  exports: [SocietiesService],
})
export class SocietiesModule {}
