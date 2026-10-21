import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class GiftCoinsDto {
  @ApiProperty()
  @IsString()
  toUserId: string;

  @ApiProperty({ example: 50 })
  @IsInt()
  @Min(1)
  amount: number;

  @ApiPropertyOptional({ example: 'Loved your post!' })
  @IsOptional()
  @IsString()
  description?: string;
}
