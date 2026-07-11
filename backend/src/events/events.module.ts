import { Module } from '@nestjs/common';
import { MembershipsModule } from '../memberships/memberships.module';
import { EventsController } from './events.controller';
import { EventsService } from './events.service';

@Module({
  imports: [MembershipsModule],
  controllers: [EventsController],
  providers: [EventsService],
})
export class EventsModule {}
