import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class ApplyJobDto {
  @ApiPropertyOptional({ example: "I've worked delivery for 2 years nearby, available immediately." })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  message?: string;
}
