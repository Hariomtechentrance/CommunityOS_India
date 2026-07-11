import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class VerifyFirebaseTokenDto {
  @ApiProperty({ description: 'Firebase ID token obtained after a successful phone sign-in' })
  @IsString()
  @MinLength(1)
  idToken: string;
}
