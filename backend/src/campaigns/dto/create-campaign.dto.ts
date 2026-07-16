import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsArray,
  IsEnum,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Min,
  MinLength,
} from 'class-validator';

const OBJECTIVES = ['SALES', 'DOWNLOADS', 'AWARENESS', 'ENGAGEMENT'] as const;
const TARGET_TYPES = ['NEARBY', 'PINCODE', 'STATES', 'ALL_INDIA'] as const;

export class CreateCampaignDto {
  @ApiProperty({ enum: OBJECTIVES })
  @IsIn(OBJECTIVES)
  objective: (typeof OBJECTIVES)[number];

  @ApiProperty({ example: '20% off this Diwali' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Visit our store this week for exclusive festive discounts.' })
  @IsString()
  description: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;

  @ApiPropertyOptional({ description: 'Where tapping the ad takes people' })
  @IsOptional()
  @IsUrl()
  ctaUrl?: string;

  @ApiProperty({ enum: TARGET_TYPES })
  @IsIn(TARGET_TYPES)
  targetType: (typeof TARGET_TYPES)[number];

  @ApiPropertyOptional({ description: 'Required when targetType = PINCODE' })
  @IsOptional()
  @IsString()
  targetPincode?: string;

  @ApiPropertyOptional({
    type: [String],
    description: 'Required when targetType = STATES - one or more state names',
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  targetStates?: string[];

  @ApiPropertyOptional({ description: 'Required when targetType = NEARBY' })
  @IsOptional()
  @IsNumber()
  targetLatitude?: number;

  @ApiPropertyOptional({ description: 'Required when targetType = NEARBY' })
  @IsOptional()
  @IsNumber()
  targetLongitude?: number;

  @ApiPropertyOptional({ description: 'Required when targetType = NEARBY, in km' })
  @IsOptional()
  @IsNumber()
  @Min(0.5)
  targetRadiusKm?: number;

  @ApiProperty({ example: 50000, description: 'Total budget in paise (₹500 = 50000)' })
  @IsInt()
  @Min(10000)
  budgetInPaise: number;
}
