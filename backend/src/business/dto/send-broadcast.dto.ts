import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUrl, MinLength } from 'class-validator';

export class SendBroadcastDto {
  @ApiProperty({ example: 'Weekend offer' })
  @IsString()
  @MinLength(2)
  title: string;

  @ApiProperty({ example: '20% off on all vegetables this Saturday & Sunday!' })
  @IsString()
  @MinLength(2)
  body: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUrl()
  imageUrl?: string;
}
