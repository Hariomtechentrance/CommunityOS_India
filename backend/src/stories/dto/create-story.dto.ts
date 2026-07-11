import { ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsUrl } from 'class-validator';

const STORY_MEDIA_TYPES = ['IMAGE', 'VIDEO'] as const;

export class CreateStoryDto {
  @ApiProperty({ example: 'https://res.cloudinary.com/.../image/upload/v1/story.jpg' })
  @IsUrl()
  mediaUrl: string;

  @ApiProperty({ enum: STORY_MEDIA_TYPES })
  @IsEnum(STORY_MEDIA_TYPES)
  mediaType: (typeof STORY_MEDIA_TYPES)[number];
}
