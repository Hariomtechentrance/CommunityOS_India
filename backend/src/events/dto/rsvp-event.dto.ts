import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

const RSVP_STATUSES = ['GOING', 'MAYBE', 'NOT_GOING'] as const;

export class RsvpEventDto {
  @ApiProperty({ enum: RSVP_STATUSES })
  @IsIn(RSVP_STATUSES)
  status: (typeof RSVP_STATUSES)[number];
}
