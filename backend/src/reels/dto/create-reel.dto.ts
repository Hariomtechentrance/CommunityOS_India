import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class CreateReelDto {
  @ApiProperty({ example: 'https://res.cloudinary.com/.../video/upload/v1/reel.mp4' })
  @IsUrl()
  videoUrl: string;

  @ApiPropertyOptional({ example: 'Sunday morning at the park!' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  caption?: string;
}
