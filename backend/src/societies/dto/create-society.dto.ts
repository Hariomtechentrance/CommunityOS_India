import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CreateSocietyDto {
  @ApiProperty({ example: 'Prestige Lakeside Habitat' })
  @IsString()
  @MinLength(2)
  name: string;

  @ApiProperty({ example: 'Whitefield Main Road' })
  @IsString()
  addressLine: string;

  @ApiProperty({ example: 'Bengaluru' })
  @IsString()
  city: string;

  @ApiProperty({ example: 'Karnataka' })
  @IsString()
  state: string;

  @ApiProperty({ example: '560066' })
  @IsString()
  pincode: string;
}
