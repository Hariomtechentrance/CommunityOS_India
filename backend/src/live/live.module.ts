import { Module } from '@nestjs/common';
import { LiveController } from './live.controller';
import { LiveGateway } from './live.gateway';

@Module({
  controllers: [LiveController],
  providers: [LiveGateway],
})
export class LiveModule {}
