import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SocietyType } from '@prisma/client';
import { IsEnum, IsOptional, IsString, MinLength } from 'class-validator';

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

  @ApiPropertyOptional({ enum: SocietyType, default: SocietyType.APARTMENT })
  @IsOptional()
  @IsEnum(SocietyType)
  type?: SocietyType;

  @ApiPropertyOptional({ example: 'sandipuniversity.edu.in' })
  @IsOptional()
  @IsString()
  emailDomain?: string;
}
