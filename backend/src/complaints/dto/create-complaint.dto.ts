import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MinLength } from 'class-validator';

export class CreateComplaintDto {
  @ApiProperty({ example: 'Plumbing' })
  @IsString()
  category: string;

  @ApiProperty({ example: 'Leaking pipe under kitchen sink' })
  @IsString()
  @MinLength(2)
  description: string;

  @ApiPropertyOptional({ example: 'A-1203' })
  @IsOptional()
  @IsString()
  unitId?: string;
}
