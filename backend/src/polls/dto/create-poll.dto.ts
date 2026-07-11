import { ApiProperty } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsString, MinLength } from 'class-validator';

export class CreatePollDto {
  @ApiProperty({ example: 'Any cricket this Sunday?' })
  @IsString()
  @MinLength(2)
  question: string;

  @ApiProperty({ example: ['Yes, 7am', 'Yes, 5pm', 'No'], minItems: 2 })
  @IsArray()
  @ArrayMinSize(2)
  @IsString({ each: true })
  options: string[];
}
