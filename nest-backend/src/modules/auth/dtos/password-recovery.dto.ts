import { IsString, IsEmail, MinLength, MaxLength, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RequestPasswordRecoveryDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;
}

export class VerifyPasswordRecoveryCodeDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '123456', description: '6-digit code sent via email' })
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Código deve ter 6 dígitos' })
  code: string;
}

export class ResetPasswordDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '123456', description: '6-digit code sent via email' })
  @IsString()
  @Matches(/^\d{6}$/, { message: 'Código deve ter 6 dígitos' })
  code: string;

  @ApiProperty({ example: '********', minLength: 8, maxLength: 100 })
  @IsString()
  @MinLength(8)
  @MaxLength(100)
  newPassword: string;
}
