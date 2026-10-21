import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CheckInDto {
  @ApiProperty({ required: false, example: 'Built the login screen today.' })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  note?: string;
}
