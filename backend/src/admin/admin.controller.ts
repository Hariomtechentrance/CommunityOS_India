import { Body, Controller, Delete, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { FeedbackCategory, FeedbackStatus, PayoutStatus, ReportStatus } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FeedbackService } from '../feedback/feedback.service';
import { ReportsService } from '../reports/reports.service';
import { WalletService } from '../wallet/wallet.service';
import { AdminService } from './admin.service';
import { SuspendUserDto } from './dto/suspend-user.dto';
import { UpdateFeedbackStatusDto } from './dto/update-feedback-status.dto';
import { UpdatePayoutStatusDto } from '../wallet/dto/update-payout-status.dto';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { PlatformAdminGuard } from './guards/platform-admin.guard';

@ApiTags('admin')
@ApiBearerAuth()
@Controller('admin')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
export class AdminController {
  constructor(
    private readonly admin: AdminService,
    private readonly reports: ReportsService,
    private readonly feedback: FeedbackService,
    private readonly wallet: WalletService,
  ) {}

  @Get('payouts')
  listPayouts(
    @Query('status') status?: PayoutStatus,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.wallet.listPayoutRequests(status, page ? Number(page) : 1, pageSize ? Number(pageSize) : 25);
  }

  @Patch('payouts/:id/status')
  updatePayoutStatus(@Param('id') id: string, @Body() dto: UpdatePayoutStatusDto) {
    return this.wallet.setPayoutStatus(id, dto.status, dto.adminNote);
  }

  @Get('feedback')
  listFeedback(
    @Query('category') category?: FeedbackCategory,
    @Query('status') status?: FeedbackStatus,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.feedback.list(
      category,
      status,
      page ? Number(page) : 1,
      pageSize ? Number(pageSize) : 25,
    );
  }

  @Patch('feedback/:id/status')
  updateFeedbackStatus(@Param('id') id: string, @Body() dto: UpdateFeedbackStatusDto) {
    return this.feedback.setStatus(id, dto.status);
  }

  @Get('reports')
  listReports(
    @Query('status') status?: ReportStatus,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.reports.list(status, page ? Number(page) : 1, pageSize ? Number(pageSize) : 25);
  }

  @Patch('reports/:id/status')
  updateReportStatus(@Param('id') id: string, @Body() dto: UpdateReportStatusDto) {
    return this.reports.setStatus(id, dto.status);
  }

  @Get('stats')
  stats() {
    return this.admin.getStats();
  }

  @Get('feature-health')
  featureHealth() {
    return this.admin.getFeatureHealth();
  }

  @Get('errors')
  listErrors(
    @Query('path') path?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.admin.listErrors(path, page ? Number(page) : 1, pageSize ? Number(pageSize) : 25);
  }

  @Get('users')
  listUsers(
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('pageSize') pageSize?: string,
  ) {
    return this.admin.listUsers(search, page ? Number(page) : 1, pageSize ? Number(pageSize) : 25);
  }

  @Get('users/:id')
  getUser(@Param('id') id: string) {
    return this.admin.getUserDetail(id);
  }

  @Patch('users/:id/suspend')
  suspend(
    @Param('id') id: string,
    @Body() dto: SuspendUserDto,
    @CurrentUser() currentUser: { userId: string },
  ) {
    return this.admin.setSuspended(id, currentUser.userId, dto.suspended);
  }

  @Delete('users/:id')
  deleteUser(@Param('id') id: string, @CurrentUser() currentUser: { userId: string }) {
    return this.admin.deleteUser(id, currentUser.userId);
  }
}
