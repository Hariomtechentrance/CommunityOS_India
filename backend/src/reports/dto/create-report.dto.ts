import { ApiProperty } from '@nestjs/swagger';
import { ReportReason } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MaxLength, ValidateIf } from 'class-validator';

export class CreateReportDto {
  @ApiProperty({ required: false })
  @ValidateIf((o: CreateReportDto) => !o.postId)
  @IsString()
  userId?: string;

  @ApiProperty({ required: false })
  @ValidateIf((o: CreateReportDto) => !o.userId)
  @IsString()
  postId?: string;

  @ApiProperty({ enum: ReportReason })
  @IsEnum(ReportReason)
  reason: ReportReason;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  details?: string;
}
