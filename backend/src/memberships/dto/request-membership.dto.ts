import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString } from 'class-validator';

export class RequestMembershipDto {
  @ApiPropertyOptional({ example: 'A-1203', description: 'Flat/unit number, e.g. "A-1203"' })
  @IsOptional()
  @IsString()
  unitNumber?: string;

  @ApiPropertyOptional({ example: 'Tower A' })
  @IsOptional()
  @IsString()
  blockName?: string;

  @ApiPropertyOptional({
    example: 'hariom@sandipuniversity.edu.in',
    description: 'COLLEGE-type societies only - claimed college email, shown to the approving admin',
  })
  @IsOptional()
  @IsEmail()
  collegeEmail?: string;
}
