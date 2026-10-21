import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { JobApplicationStatus, JobStatus, JobType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateJobDto } from './dto/create-job.dto';

@Injectable()
export class JobsService {
  constructor(private readonly prisma: PrismaService) {}

  create(posterId: string, dto: CreateJobDto) {
    return this.prisma.jobPosting.create({
      data: { posterId, ...dto },
    });
  }

  listForArea(area: string, jobType?: JobType) {
    return this.prisma.jobPosting.findMany({
      where: { area, status: JobStatus.OPEN, ...(jobType ? { jobType } : {}) },
      include: { poster: true, _count: { select: { applications: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  listMine(posterId: string) {
    return this.prisma.jobPosting.findMany({
      where: { posterId },
      include: { _count: { select: { applications: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findOne(id: string) {
    const job = await this.prisma.jobPosting.findUnique({
      where: { id },
      include: { poster: true, _count: { select: { applications: true } } },
    });
    if (!job) throw new NotFoundException('Job not found');
    return job;
  }

  async setStatus(id: string, posterId: string, status: JobStatus) {
    const job = await this.prisma.jobPosting.findUnique({ where: { id } });
    if (!job) throw new NotFoundException('Job not found');
    if (job.posterId !== posterId) throw new ForbiddenException('Only the poster can update this job');
    return this.prisma.jobPosting.update({ where: { id }, data: { status } });
  }

  async remove(id: string, posterId: string) {
    const job = await this.prisma.jobPosting.findUnique({ where: { id } });
    if (!job) throw new NotFoundException('Job not found');
    if (job.posterId !== posterId) throw new ForbiddenException('Only the poster can delete this job');
    await this.prisma.jobPosting.delete({ where: { id } });
    return { deleted: true };
  }

  async apply(jobId: string, applicantId: string, message?: string) {
    const job = await this.prisma.jobPosting.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Job not found');
    if (job.posterId === applicantId) throw new ForbiddenException("You can't apply to your own job posting");
    if (job.status !== JobStatus.OPEN) throw new ForbiddenException('This job is no longer accepting applications');

    return this.prisma.jobApplication.upsert({
      where: { jobId_applicantId: { jobId, applicantId } },
      update: { message },
      create: { jobId, applicantId, message },
    });
  }

  async listApplications(jobId: string, callerId: string) {
    const job = await this.prisma.jobPosting.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Job not found');
    if (job.posterId !== callerId) throw new ForbiddenException('Only the poster can view applicants');
    return this.prisma.jobApplication.findMany({
      where: { jobId },
      include: { applicant: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async updateApplicationStatus(
    jobId: string,
    applicationId: string,
    callerId: string,
    status: JobApplicationStatus,
  ) {
    const job = await this.prisma.jobPosting.findUnique({ where: { id: jobId } });
    if (!job) throw new NotFoundException('Job not found');
    if (job.posterId !== callerId) throw new ForbiddenException('Only the poster can update applicants');

    const application = await this.prisma.jobApplication.findUnique({ where: { id: applicationId } });
    if (!application || application.jobId !== jobId) throw new NotFoundException('Application not found');

    return this.prisma.jobApplication.update({ where: { id: applicationId }, data: { status } });
  }

  listMyApplications(applicantId: string) {
    return this.prisma.jobApplication.findMany({
      where: { applicantId },
      include: { job: true },
      orderBy: { createdAt: 'desc' },
    });
  }
}
