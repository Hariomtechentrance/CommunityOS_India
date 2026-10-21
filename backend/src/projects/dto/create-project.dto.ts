import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateProjectDto {
  @ApiProperty({ example: 'My Startup Journey' })
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  name: string;

  @ApiProperty({ example: 'Building a hyperlocal community app for India.' })
  @IsString()
  @MinLength(2)
  @MaxLength(1000)
  description: string;

  @ApiPropertyOptional({ example: 'Startup' })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  category?: string;
}
