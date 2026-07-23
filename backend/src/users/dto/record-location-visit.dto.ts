import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber } from 'class-validator';

export class RecordLocationVisitDto {
  @ApiPropertyOptional({ example: 19.1197 })
  @IsNumber()
  lat: number;

  @ApiPropertyOptional({ example: 72.8468 })
  @IsNumber()
  lng: number;
}
