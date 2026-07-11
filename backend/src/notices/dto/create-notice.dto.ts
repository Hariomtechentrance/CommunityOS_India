import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateNoticeDto {
  @ApiProperty({ example: 'Water supply maintenance on Sunday' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: 'Water will be shut off from 10am-2pm for tank cleaning.' })
  @IsString()
  body: string;

  @ApiPropertyOptional({ default: false })
  @IsOptional()
  @IsBoolean()
  pinned?: boolean;
}
