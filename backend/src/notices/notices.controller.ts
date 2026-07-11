import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { MembershipRole } from '../memberships/common/roles.enum';
import { Roles } from '../memberships/decorators/roles.decorator';
import { SocietyRolesGuard } from '../memberships/guards/society-roles.guard';
import { CreateNoticeDto } from './dto/create-notice.dto';
import { NoticesService } from './notices.service';

@ApiTags('notices')
@ApiBearerAuth()
@Controller('societies/:societyId/notices')
@UseGuards(JwtAuthGuard, SocietyRolesGuard)
export class NoticesController {
  constructor(private readonly notices: NoticesService) {}

  @Post()
  @Roles(MembershipRole.COMMITTEE_ADMIN, MembershipRole.SUPER_ADMIN)
  create(
    @Param('societyId') societyId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: CreateNoticeDto,
  ) {
    return this.notices.create(societyId, user.userId, dto);
  }

  @Get()
  list(@Param('societyId') societyId: string) {
    return this.notices.listForSociety(societyId);
  }
}
