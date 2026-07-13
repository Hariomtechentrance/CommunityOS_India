import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsUrl } from 'class-validator';

const STORY_MEDIA_TYPES = ['IMAGE', 'VIDEO'] as const;

export class CreateStoryDto {
  @ApiProperty({ example: 'https://res.cloudinary.com/.../image/upload/v1/story.jpg' })
  @IsUrl()
  mediaUrl: string;

  @ApiProperty({ enum: STORY_MEDIA_TYPES })
  @IsEnum(STORY_MEDIA_TYPES)
  mediaType: (typeof STORY_MEDIA_TYPES)[number];

  @ApiPropertyOptional({
    example: 'https://res.cloudinary.com/.../video/upload/v1/voice-note.m4a',
    description: 'Optional background audio clip - only meaningful for IMAGE stories.',
  })
  @IsOptional()
  @IsUrl()
  audioUrl?: string;
}
