import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class SuspendUserDto {
  @ApiProperty()
  @IsBoolean()
  suspended: boolean;
}
