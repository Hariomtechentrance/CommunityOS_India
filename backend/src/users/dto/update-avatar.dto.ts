import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class UpdateAvatarDto {
  @ApiProperty({ example: 'https://res.cloudinary.com/demo/image/upload/v1/avatar.jpg' })
  @IsString()
  @MinLength(1)
  avatarUrl: string;
}
