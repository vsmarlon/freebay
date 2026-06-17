import { IsString, MinLength, MaxLength, IsEmail, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class RegisterDTO {
  @ApiProperty({ example: 'John Doe', minLength: 2, maxLength: 50 })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  @SanitizeText()
  displayName: string;

  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '********', minLength: 8, maxLength: 100 })
  @IsString()
  @MinLength(8)
  @MaxLength(100)
  password: string;

  @ApiPropertyOptional({ example: 'São Paulo' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  city?: string;

  @ApiPropertyOptional({ example: 'SP' })
  @IsOptional()
  @IsString()
  state?: string;
}

export class LoginDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ example: '********', minLength: 8 })
  @IsString()
  @MinLength(8)
  password: string;
}

export class ForgotPasswordDTO {
  @ApiProperty({ example: 'john@example.com' })
  @IsEmail()
  email: string;
}
