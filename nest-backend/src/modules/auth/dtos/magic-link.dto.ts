import { ApiProperty } from '@nestjs/swagger';
import { Equals, IsBoolean, IsEmail, IsIn, IsString, Length } from 'class-validator';

export class RequestMagicLinkDTO {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  @Equals(true)
  consent: boolean;

  @ApiProperty({ enum: ['pt-BR', 'en'], example: 'pt-BR' })
  @IsIn(['pt-BR', 'en'])
  locale: 'pt-BR' | 'en';
}

export class ConsumeMagicLinkDTO {
  @ApiProperty({ minLength: 32 })
  @IsString()
  @Length(32, 512)
  token: string;
}
