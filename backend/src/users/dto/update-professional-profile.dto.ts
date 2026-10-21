import { ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateProfessionalProfileDto {
  @ApiPropertyOptional({ example: 'Software Developer' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  headline?: string;

  @ApiPropertyOptional({ example: ['React', 'Flutter', 'Node.js'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(20)
  skills?: string[];

  @ApiPropertyOptional({ example: ['Freelance', 'Jobs', 'Collaboration'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(10)
  availableFor?: string[];
}
