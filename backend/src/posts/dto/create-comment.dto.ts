import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CreateCommentDto {
  @ApiProperty({ example: 'I saw a cat matching that description near the clubhouse.' })
  @IsString()
  @MinLength(1)
  body: string;
}
