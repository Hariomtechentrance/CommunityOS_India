import { ApiProperty } from '@nestjs/swagger';
import { IsDateString, IsString, MinLength } from 'class-validator';

export class CreateEventDto {
  @ApiProperty({ example: 'Sunday Morning Cricket' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Friendly match, all skill levels welcome.' })
  @IsString()
  description: string;

  @ApiProperty({ example: 'Society clubhouse ground' })
  @IsString()
  location: string;

  @ApiProperty({ example: '2026-07-12T07:00:00.000Z' })
  @IsDateString()
  startAt: string;
}
