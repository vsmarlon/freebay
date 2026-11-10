import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsIn, IsString, Length, Matches, MaxLength, MinLength } from 'class-validator';

export class RequestWebPasswordResetDTO {
  @ApiProperty({ example: 'user@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ enum: ['pt-BR', 'en'] })
  @IsIn(['pt-BR', 'en'])
  locale: 'pt-BR' | 'en';
}

export class ResetWebPasswordDTO {
  @ApiProperty({ minLength: 43, maxLength: 43 })
  @IsString()
  @Length(43, 43)
  @Matches(/^[A-Za-z0-9_-]{43}$/)
  token: string;

  @ApiProperty({ minLength: 8, maxLength: 100 })
  @IsString()
  @MinLength(8)
  @MaxLength(100)
  newPassword: string;
}
