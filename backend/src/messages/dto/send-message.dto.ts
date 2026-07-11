import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

const MESSAGE_KINDS = ['TEXT', 'STICKER'] as const;

export class SendMessageDto {
  @ApiProperty({ example: 'cmr7i089c0003g1mpcqqdhivx' })
  @IsString()
  toUserId: string;

  @ApiProperty({ example: 'Hi, is the maid position still open?' })
  @IsString()
  @MinLength(1)
  body: string;

  @ApiPropertyOptional({ enum: MESSAGE_KINDS, default: 'TEXT' })
  @IsOptional()
  @IsEnum(MESSAGE_KINDS)
  kind?: (typeof MESSAGE_KINDS)[number];
}
