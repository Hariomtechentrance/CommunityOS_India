import { ApiPropertyOptional } from '@nestjs/swagger';
import { MessagePrivacy } from '@prisma/client';
import { IsBoolean, IsEnum, IsOptional } from 'class-validator';

export class UpdateNotificationSettingsDto {
  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  activityNotificationsEnabled?: boolean;

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  hideLikeCounts?: boolean;

  @ApiPropertyOptional({ enum: MessagePrivacy })
  @IsOptional()
  @IsEnum(MessagePrivacy)
  allowMessagesFrom?: MessagePrivacy;
}
