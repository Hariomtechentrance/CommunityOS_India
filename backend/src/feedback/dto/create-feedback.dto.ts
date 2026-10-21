import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { FeedbackCategory } from '@prisma/client';
import { IsEnum, IsInt, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateFeedbackDto {
  @ApiProperty({ enum: FeedbackCategory })
  @IsEnum(FeedbackCategory)
  category: FeedbackCategory;

  @ApiProperty({ example: 'The map screen crashes when I tap a marker.' })
  @IsString()
  @MinLength(2)
  @MaxLength(2000)
  message: string;

  @ApiPropertyOptional({ example: 5, description: 'Only used for REVIEW category' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(5)
  rating?: number;
}
