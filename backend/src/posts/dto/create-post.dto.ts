import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

const POST_TYPES = ['GENERAL', 'QUESTION', 'RECOMMENDATION', 'LOST_FOUND'] as const;

export class CreatePostDto {
  @ApiPropertyOptional({ enum: POST_TYPES, default: 'GENERAL' })
  @IsOptional()
  @IsEnum(POST_TYPES)
  type?: (typeof POST_TYPES)[number];

  @ApiPropertyOptional({ example: 'Missing cat near Tower B' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiProperty({ example: 'Has anyone seen a grey tabby cat near Tower B today?' })
  @IsString()
  @MinLength(2)
  body: string;
}
