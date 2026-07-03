import { IsString, MinLength, MaxLength, IsEmail, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class RegisterDTO {
  @ApiProperty({ example: 'John Doe', minLength: 2, maxLength: 50 })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  @SanitizeText()
  readonly displayName: string;

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

export class LogoutDTO {
  @ApiPropertyOptional({ description: 'Refresh token to blacklist alongside the access token' })
  @IsOptional()
  @IsString()
  readonly refreshToken?: string;
}

export class ForgotPasswordDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  readonly email: string;
}
