import { Module } from '@nestjs/common';
import { BlocksModule } from '../blocks/blocks.module';
import { MutesModule } from '../mutes/mutes.module';
import { ConnectController } from './connect.controller';
import { ConnectService } from './connect.service';

@Module({
  imports: [BlocksModule, MutesModule],
  controllers: [ConnectController],
  providers: [ConnectService],
})
export class ConnectModule {}
