import { Module } from '@nestjs/common';
import { MembershipsModule } from '../memberships/memberships.module';
import { PollsController } from './polls.controller';
import { PollsService } from './polls.service';

@Module({
  imports: [MembershipsModule],
  controllers: [PollsController],
  providers: [PollsService],
})
export class PollsModule {}
