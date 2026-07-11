import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

const STATUSES = ['ACTIVE', 'CLOSED'] as const;

export class UpdateListingStatusDto {
  @ApiProperty({ enum: STATUSES })
  @IsIn(STATUSES)
  status: (typeof STATUSES)[number];
}
