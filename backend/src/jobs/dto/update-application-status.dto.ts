import { ApiProperty } from '@nestjs/swagger';
import { JobApplicationStatus } from '@prisma/client';
import { IsEnum } from 'class-validator';

export class UpdateApplicationStatusDto {
  @ApiProperty({ enum: JobApplicationStatus })
  @IsEnum(JobApplicationStatus)
  status: JobApplicationStatus;
}
