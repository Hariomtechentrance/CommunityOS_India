import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CreateReelCommentDto {
  @ApiProperty({ example: 'Love this!' })
  @IsString()
  @MinLength(1)
  body: string;
}
