import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class UpdateFcmTokenDto {
  @ApiProperty({ example: 'e7Gd...browser-push-token' })
  @IsString()
  @MinLength(1)
  token: string;
}
