import { ApiPropertyOptional } from '@nestjs/swagger';
import { ArrayMaxSize, IsArray, IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdateConnectSettingsDto {
  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  connectEnabled?: boolean;

  @ApiPropertyOptional({ example: ['Programming', 'AI', 'Cricket'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  @ArrayMaxSize(15)
  interests?: string[];
}
