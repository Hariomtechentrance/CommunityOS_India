import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class AskCommunityDto {
  @ApiProperty({ example: 'Who discussed the water supply issue this week?' })
  @IsString()
  @MinLength(1)
  @MaxLength(500)
  question: string;
}
