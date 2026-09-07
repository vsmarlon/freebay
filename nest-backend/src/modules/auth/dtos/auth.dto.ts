import { IsString, MinLength, MaxLength, IsEmail, IsOptional, Matches } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export const USERNAME_REGEX = /^[a-z0-9_]{3,20}$/;

export class RegisterDTO {
  @ApiProperty({ example: 'John Doe', minLength: 2, maxLength: 50 })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  @SanitizeText()
  readonly displayName: string;

  @ApiProperty({ example: 'john_doe', minLength: 3, maxLength: 20, description: '3-20 chars, lowercase letters/numbers/underscore only' })
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @Matches(USERNAME_REGEX, { message: 'Nome de usuário deve ter 3-20 caracteres e conter apenas letras minúsculas, números e underscore' })
  readonly username: string;

  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  readonly email: string;

  @ApiProperty({ example: '********', minLength: 8, maxLength: 100 })
  @IsString()
  @MinLength(8)
  @MaxLength(100)
  readonly password: string;

  @ApiPropertyOptional({ example: 'São Paulo' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly city?: string;

  @ApiPropertyOptional({ example: 'SP' })
  @IsOptional()
  @IsString()
  readonly state?: string;
}

export class LoginDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  readonly email: string;

  @ApiProperty({ example: '********', minLength: 8 })
  @IsString()
  @MinLength(8)
  readonly password: string;
}

export class BiometricLoginDTO {
  @ApiProperty({ description: 'Backend-issued biometric token (JWT type: biometric)' })
  @IsString()
  readonly biometricToken: string;
}

export class GoogleAuthDTO {
  @ApiProperty({ description: 'Google ID token from google_sign_in' })
  @IsString()
  readonly idToken: string;
}

export class CompleteProfileDTO {
  @ApiProperty({ example: 'john_doe', minLength: 3, maxLength: 20, description: '3-20 chars, lowercase letters/numbers/underscore only' })
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @Matches(USERNAME_REGEX, { message: 'Nome de usuário deve ter 3-20 caracteres e conter apenas letras minúsculas, números e underscore' })
  readonly username: string;

  @ApiPropertyOptional({ example: 'John Doe', minLength: 2, maxLength: 50 })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  @SanitizeText()
  readonly displayName?: string;

  @ApiPropertyOptional({ example: 'São Paulo' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly city?: string;

  @ApiPropertyOptional({ example: 'SP' })
  @IsOptional()
  @IsString()
  readonly state?: string;
}

export class ForgotPasswordDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  readonly email: string;
}

export class UsernameAvailabilityQueryDTO {
  @ApiProperty({ example: 'john_doe', minLength: 1, maxLength: 20 })
  @IsString()
  @MinLength(1)
  @MaxLength(20)
  readonly u: string;
}
