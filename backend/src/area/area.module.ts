import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { GeocodingModule } from '../geocoding/geocoding.module';
import { AlertsGateway } from './alerts.gateway';
import { AreaPostsController } from './area-posts.controller';
import { AreaService } from './area.service';
import { EmergencyAlertService } from './emergency-alert.service';

@Module({
  imports: [GeocodingModule, AuthModule],
  controllers: [AreaPostsController],
  providers: [AreaService, AlertsGateway, EmergencyAlertService],
})
export class AreaModule {}
