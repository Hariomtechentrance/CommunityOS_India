import { Body, Controller, Get, Param, Patch, Post, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MembershipRole } from '../memberships/common/roles.enum';
import { Roles } from '../memberships/decorators/roles.decorator';
import { SocietyRolesGuard } from '../memberships/guards/society-roles.guard';
import { ComplaintsService } from './complaints.service';
import { CreateComplaintDto } from './dto/create-complaint.dto';
import { UpdateComplaintStatusDto } from './dto/update-complaint-status.dto';

const STAFF_ROLES = [MembershipRole.COMMITTEE_ADMIN, MembershipRole.SUPER_ADMIN, MembershipRole.SECURITY];

@ApiTags('complaints')
@ApiBearerAuth()
@Controller('societies/:societyId/complaints')
@UseGuards(JwtAuthGuard, SocietyRolesGuard)
export class ComplaintsController {
  constructor(private readonly complaints: ComplaintsService) {}

  @Post()
  create(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateComplaintDto,
  ) {
    return this.complaints.create(societyId, user.userId, dto);
  }

  @Get()
  list(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Req() req: any,
  ) {
    const isStaff = STAFF_ROLES.includes(req.membership.role);
    return this.complaints.listForSociety(societyId, isStaff ? undefined : user.userId);
  }

  @Patch(':complaintId/status')
  @Roles(...STAFF_ROLES)
  updateStatus(
    @Param('societyId') societyId: string,
    @Param('complaintId') complaintId: string,
    @Body() dto: UpdateComplaintStatusDto,
  ) {
    return this.complaints.updateStatus(societyId, complaintId, dto.status);
  }
}
