import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class CreateProjectUpdateDto {
  @ApiPropertyOptional({ example: 17 })
  @IsOptional()
  @IsInt()
  @Min(0)
  dayNumber?: number;

  @ApiProperty({ example: 'MVP completed and deployed.' })
  @IsString()
  @MinLength(1)
  body: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  imageUrl?: string;
}
