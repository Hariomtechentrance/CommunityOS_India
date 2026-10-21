import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { JobStatus, JobType } from '@prisma/client';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ApplyJobDto } from './dto/apply-job.dto';
import { CreateJobDto } from './dto/create-job.dto';
import { UpdateApplicationStatusDto } from './dto/update-application-status.dto';
import { JobsService } from './jobs.service';

@ApiTags('jobs')
@ApiBearerAuth()
@Controller('jobs')
@UseGuards(JwtAuthGuard)
export class JobsController {
  constructor(private readonly jobs: JobsService) {}

  @Post()
  create(@CurrentUser() user: { userId: string }, @Body() dto: CreateJobDto) {
    return this.jobs.create(user.userId, dto);
  }

  @Get()
  list(@Query('area') area: string, @Query('jobType') jobType?: JobType) {
    return this.jobs.listForArea(area, jobType);
  }

  // Must be registered before ':id' so these aren't swallowed as an :id param.
  @Get('mine')
  listMine(@CurrentUser() user: { userId: string }) {
    return this.jobs.listMine(user.userId);
  }

  @Get('my-applications')
  listMyApplications(@CurrentUser() user: { userId: string }) {
    return this.jobs.listMyApplications(user.userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.jobs.findOne(id);
  }

  @Patch(':id/status')
  setStatus(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body('status') status: JobStatus,
  ) {
    return this.jobs.setStatus(id, user.userId, status);
  }

  @Delete(':id')
  remove(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.jobs.remove(id, user.userId);
  }

  @Post(':id/apply')
  apply(
    @Param('id') id: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: ApplyJobDto,
  ) {
    return this.jobs.apply(id, user.userId, dto.message);
  }

  @Get(':id/applications')
  listApplications(@Param('id') id: string, @CurrentUser() user: { userId: string }) {
    return this.jobs.listApplications(id, user.userId);
  }

  @Patch(':id/applications/:applicationId/status')
  updateApplicationStatus(
    @Param('id') id: string,
    @Param('applicationId') applicationId: string,
    @CurrentUser() user: { userId: string },
    @Body() dto: UpdateApplicationStatusDto,
  ) {
    return this.jobs.updateApplicationStatus(id, applicationId, user.userId, dto.status);
  }
}
