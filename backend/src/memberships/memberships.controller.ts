import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { Roles } from './decorators/roles.decorator';
import { SocietyRolesGuard } from './guards/society-roles.guard';
import { MembershipsService } from './memberships.service';
import { RequestMembershipDto } from './dto/request-membership.dto';
import { UpdateMembershipStatusDto } from './dto/update-membership-status.dto';
import { MembershipRole, MembershipStatus } from './common/roles.enum';

@ApiTags('memberships')
@ApiBearerAuth()
@Controller('societies/:societyId/memberships')
export class MembershipsController {
  constructor(private readonly memberships: MembershipsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  requestToJoin(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: RequestMembershipDto,
  ) {
    return this.memberships.requestToJoin(user.userId, societyId, dto);
  }

  @Get('me')
  @UseGuards(JwtAuthGuard)
  findMine(@Param('societyId') societyId: string, @CurrentUser() user: { userId: string }) {
    return this.memberships.findMine(user.userId, societyId);
  }

  @Get()
  @UseGuards(JwtAuthGuard, SocietyRolesGuard)
  @Roles(MembershipRole.COMMITTEE_ADMIN, MembershipRole.SUPER_ADMIN)
  list(
    @Param('societyId') societyId: string,
    @Query('status') status?: MembershipStatus,
  ) {
    return this.memberships.listForSociety(societyId, status);
  }

  @Patch(':membershipId')
  @UseGuards(JwtAuthGuard, SocietyRolesGuard)
  @Roles(MembershipRole.COMMITTEE_ADMIN, MembershipRole.SUPER_ADMIN)
  updateStatus(
    @Param('societyId') societyId: string,
    @Param('membershipId') membershipId: string,
    @Body() dto: UpdateMembershipStatusDto,
  ) {
    return this.memberships.updateStatus(societyId, membershipId, dto.status);
  }
}
