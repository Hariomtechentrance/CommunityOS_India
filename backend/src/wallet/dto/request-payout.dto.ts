import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Min, MinLength } from 'class-validator';

export class RequestPayoutDto {
  @ApiProperty({ example: 500 })
  @IsInt()
  @Min(1)
  amountCoins: number;

  @ApiProperty({ example: 'Priya Sharma' })
  @IsString()
  @MinLength(1)
  payeeName: string;

  @ApiPropertyOptional({ example: 'priya@okaxis' })
  @IsOptional()
  @IsString()
  upiId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  bankAccountNumber?: string;

  @ApiPropertyOptional({ example: 'HDFC0001234' })
  @IsOptional()
  @IsString()
  bankIfsc?: string;
}
