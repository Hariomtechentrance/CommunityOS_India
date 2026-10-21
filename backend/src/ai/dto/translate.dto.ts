import { ApiProperty } from '@nestjs/swagger';
import { IsString, MaxLength, MinLength } from 'class-validator';

export class TranslateDto {
  @ApiProperty({ example: 'Bhai kal Bangalore mein cricket khelenge?' })
  @IsString()
  @MinLength(1)
  @MaxLength(2000)
  text: string;

  @ApiProperty({ example: 'kn', description: 'Target language code (en, hi, mr, kn, ta, te, bn, gu, ml, pa)' })
  @IsString()
  targetLanguage: string;
}
