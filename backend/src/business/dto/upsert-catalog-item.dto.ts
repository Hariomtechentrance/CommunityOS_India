import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { IsArray, IsBoolean, IsNumber, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class UpsertCatalogItemDto {
  @ApiProperty({ example: 'Alphonso Mango (1kg)' })
  @IsString()
  @MinLength(1)
  name: string;

  @ApiPropertyOptional({ example: 'Ripe, farm-sourced Alphonso mangoes.' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ example: 250 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  imageUrls?: string[];

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  inStock?: boolean;
}
