import { ApiProperty } from '@nestjs/swagger';
import { IsNumber } from 'class-validator';

export class DetectAreaDto {
  @ApiProperty({ example: 19.1197 })
  @IsNumber()
  lat: number;

  @ApiProperty({ example: 72.8468 })
  @IsNumber()
  lng: number;
}
