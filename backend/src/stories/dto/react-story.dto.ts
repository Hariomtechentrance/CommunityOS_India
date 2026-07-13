import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class ReactStoryDto {
  @ApiProperty({ example: '❤️' })
  @IsString()
  @MinLength(1)
  @MaxLength(8)
  emoji: string;
}
