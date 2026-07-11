import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMaxSize,
  IsArray,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  MinLength,
} from 'class-validator';

const LISTING_CATEGORIES = [
  'ITEM_SALE',
  'ITEM_FREE',
  'ITEM_RENT',
  'PROPERTY_SALE',
  'PROPERTY_RENT',
] as const;

export class CreateListingDto {
  @ApiProperty({ enum: LISTING_CATEGORIES })
  @IsEnum(LISTING_CATEGORIES)
  category: (typeof LISTING_CATEGORIES)[number];

  @ApiProperty({ example: 'Study table, barely used' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Wooden study table, 3ft x 2ft, no scratches.' })
  @IsString()
  description: string;

  @ApiPropertyOptional({ example: 1500, description: 'Omit for free/donate listings' })
  @IsOptional()
  @IsNumber()
  price?: number;

  @ApiPropertyOptional({ type: [String], maxItems: 5 })
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(5)
  @IsUrl({}, { each: true })
  imageUrls?: string[];
}
