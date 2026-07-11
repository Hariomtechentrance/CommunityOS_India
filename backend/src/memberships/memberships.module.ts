import { Module } from '@nestjs/common';
import { MembershipsController } from './memberships.controller';
import { MembershipsService } from './memberships.service';
import { SocietyRolesGuard } from './guards/society-roles.guard';

@Module({
  controllers: [MembershipsController],
  providers: [MembershipsService, SocietyRolesGuard],
  exports: [MembershipsService, SocietyRolesGuard],
})
export class MembershipsModule {}
