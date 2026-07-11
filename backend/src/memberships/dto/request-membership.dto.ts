import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class RequestMembershipDto {
  @ApiPropertyOptional({ example: 'A-1203', description: 'Flat/unit number, e.g. "A-1203"' })
  @IsOptional()
  @IsString()
  unitNumber?: string;

  @ApiPropertyOptional({ example: 'Tower A' })
  @IsOptional()
  @IsString()
  blockName?: string;
}
