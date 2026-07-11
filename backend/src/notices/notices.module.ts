import { Module } from '@nestjs/common';
import { MembershipsModule } from '../memberships/memberships.module';
import { NoticesController } from './notices.controller';
import { NoticesService } from './notices.service';

@Module({
  imports: [MembershipsModule],
  controllers: [NoticesController],
  providers: [NoticesService],
})
export class NoticesModule {}
