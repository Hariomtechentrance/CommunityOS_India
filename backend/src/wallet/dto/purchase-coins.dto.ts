import { ApiProperty } from '@nestjs/swagger';
import { IsInt, Min } from 'class-validator';

export class PurchaseCoinsDto {
  @ApiProperty({ example: 10000, description: 'Amount in paise (₹100 = 10000)' })
  @IsInt()
  @Min(1000)
  amountInPaise: number;
}
