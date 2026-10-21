import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AiModule } from '../ai/ai.module';
import { BlocksModule } from '../blocks/blocks.module';
import { FollowsModule } from '../follows/follows.module';
import { GeocodingModule } from '../geocoding/geocoding.module';
import { MutesModule } from '../mutes/mutes.module';
import { AlertsGateway } from './alerts.gateway';
import { AreaPostsController } from './area-posts.controller';
import { AreaService } from './area.service';
import { EmergencyAlertService } from './emergency-alert.service';

@Module({
  imports: [GeocodingModule, AuthModule, FollowsModule, BlocksModule, MutesModule, AiModule],
  controllers: [AreaPostsController],
  providers: [AreaService, AlertsGateway, EmergencyAlertService],
})
export class AreaModule {}
