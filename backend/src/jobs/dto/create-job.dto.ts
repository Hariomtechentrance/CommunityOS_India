import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { JobType } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CreateJobDto {
  @ApiProperty({ example: 'Nashik Satpur' })
  @IsString()
  @MinLength(1)
  area: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  pincode?: string;

  @ApiProperty({ example: 'Delivery staff needed' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Looking for 2 delivery riders, own two-wheeler required.' })
  @IsString()
  @MinLength(2)
  description: string;

  @ApiPropertyOptional({ example: 'Satpur Fresh Mart' })
  @IsOptional()
  @IsString()
  companyName?: string;

  @ApiProperty({ enum: JobType })
  @IsEnum(JobType)
  jobType: JobType;

  @ApiPropertyOptional({ example: 12000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  salaryMin?: number;

  @ApiPropertyOptional({ example: 18000 })
  @IsOptional()
  @IsInt()
  @Min(0)
  salaryMax?: number;

  @ApiPropertyOptional({ example: 'monthly' })
  @IsOptional()
  @IsString()
  salaryPeriod?: string;

  @ApiPropertyOptional({ example: 'Near Satpur MIDC signal' })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  contactPhone?: string;
}
