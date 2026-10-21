import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min, MinLength } from 'class-validator';

export class CreateGoalCommunityDto {
  @ApiProperty({ example: '100 Days Coding Challenge' })
  @IsString()
  @MinLength(3)
  @MaxLength(100)
  title: string;

  @ApiProperty({ example: 'Check in every day you write code, however small.' })
  @IsString()
  @MinLength(3)
  @MaxLength(1000)
  description: string;

  @ApiProperty({ required: false, example: 'Coding' })
  @IsOptional()
  @IsString()
  @MaxLength(40)
  category?: string;

  @ApiProperty({ example: 100 })
  @IsInt()
  @Min(1)
  @Max(1000)
  durationDays: number;

  @ApiPropertyOptional({ example: 0, description: 'One-time join fee in Niikat Coins, 0 = free' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(100000)
  joinCostCoins?: number;
}
