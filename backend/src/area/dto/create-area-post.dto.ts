import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  Min,
  MinLength,
} from 'class-validator';

const AREA_POST_KINDS = [
  'UPDATE',
  'SHOP',
  'SPORTS_INVITE',
  'HELP_REQUEST',
  'SOCIAL_EVENT',
  'SAFETY_ALERT',
  'SERVICE_REQUEST',
  'EMERGENCY_SOS',
] as const;

const AREA_POST_VISIBILITIES = ['PINCODE_ONLY', 'NEARBY', 'ALL_INDIA'] as const;

const EMERGENCY_CATEGORIES = [
  'ACCIDENT',
  'MEDICAL',
  'FIRE',
  'WOMENS_SAFETY',
  'OTHER',
] as const;

export class CreateAreaPostDto {
  @ApiProperty({ example: 'Nashik Satpur' })
  @IsString()
  @MinLength(1)
  area: string;

  @ApiProperty({ enum: AREA_POST_KINDS })
  @IsEnum(AREA_POST_KINDS)
  kind: (typeof AREA_POST_KINDS)[number];

  @ApiProperty({ example: 'MIDC road under maintenance' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Road closed for repairs near the water tank, expect delays.' })
  @IsString()
  description: string;

  @ApiPropertyOptional({ type: [String], maxItems: 5 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsUrl({}, { each: true })
  imageUrls?: string[];

  @ApiPropertyOptional({ example: 'Near Satpur MIDC water tank' })
  @IsOptional()
  @IsString()
  location?: string;

  @ApiPropertyOptional({ example: 'Badminton' })
  @IsOptional()
  @IsString()
  sportName?: string;

  @ApiPropertyOptional({ enum: AREA_POST_VISIBILITIES, default: 'NEARBY' })
  @IsOptional()
  @IsEnum(AREA_POST_VISIBILITIES)
  visibility?: (typeof AREA_POST_VISIBILITIES)[number];

  @ApiPropertyOptional({
    example: 5,
    description:
      'Broadcast radius in km for NEARBY-visibility posts - only viewers within this ' +
      "distance of the post's location will see it. Ignored for PINCODE_ONLY/ALL_INDIA.",
  })
  @IsOptional()
  @IsNumber()
  @Min(0.5)
  radiusKm?: number;

  @ApiPropertyOptional({ example: 'Maid / Driver / Housekeeping' })
  @IsOptional()
  @IsString()
  serviceType?: string;

  @ApiPropertyOptional({ example: 'Restaurant' })
  @IsOptional()
  @IsString()
  businessCategory?: string;

  @ApiPropertyOptional({ example: '20% off this week' })
  @IsOptional()
  @IsString()
  offerText?: string;

  @ApiPropertyOptional({ example: 'https://res.cloudinary.com/.../video/upload/v1/clip.mp4' })
  @IsOptional()
  @IsUrl()
  videoUrl?: string;

  @ApiPropertyOptional({ example: 2.5, description: 'Trim start, in seconds' })
  @IsOptional()
  @IsNumber()
  videoTrimStart?: number;

  @ApiPropertyOptional({ example: 12, description: 'Trim end, in seconds' })
  @IsOptional()
  @IsNumber()
  videoTrimEnd?: number;

  @ApiPropertyOptional({ example: 'https://res.cloudinary.com/.../video/upload/v1/note.m4a' })
  @IsOptional()
  @IsUrl()
  audioUrl?: string;

  @ApiPropertyOptional({ enum: EMERGENCY_CATEGORIES })
  @IsOptional()
  @IsEnum(EMERGENCY_CATEGORIES)
  emergencyCategory?: (typeof EMERGENCY_CATEGORIES)[number];

  @ApiPropertyOptional({ example: '8 AM - 10 PM' })
  @IsOptional()
  @IsString()
  businessHours?: string;

  @ApiPropertyOptional({ example: '6:00 PM - 7:00 PM' })
  @IsOptional()
  @IsString()
  activityTime?: string;

  @ApiPropertyOptional({ example: 1 })
  @IsOptional()
  @IsInt()
  @Min(1)
  partnersNeeded?: number;
}
