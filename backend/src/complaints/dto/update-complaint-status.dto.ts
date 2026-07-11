import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

const STATUSES = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'] as const;

export class UpdateComplaintStatusDto {
  @ApiProperty({ enum: STATUSES })
  @IsIn(STATUSES)
  status: (typeof STATUSES)[number];
}
