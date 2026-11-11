import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, IsUrl, MinLength } from 'class-validator';

export class UpsertBusinessProfileDto {
  @ApiProperty({ example: 'Satpur Fresh Mart' })
  @IsString()
  @MinLength(2)
  businessName: string;

  @ApiProperty({ example: 'Grocery' })
  @IsString()
  @MinLength(2)
  category: string;

  @ApiPropertyOptional({ example: 'Fresh vegetables and daily essentials, home delivery available.' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  logoUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  coverImageUrl?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  website?: string;
}
