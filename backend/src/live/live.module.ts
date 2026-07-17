import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { LiveController } from './live.controller';
import { LiveGateway } from './live.gateway';

@Module({
  imports: [AuthModule],
  controllers: [LiveController],
  providers: [LiveGateway],
})
export class LiveModule {}
