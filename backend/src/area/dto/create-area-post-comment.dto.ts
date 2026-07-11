import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CreateAreaPostCommentDto {
  @ApiProperty({ example: 'I can help, calling you now.' })
  @IsString()
  @MinLength(1)
  body: string;
}
