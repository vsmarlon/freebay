import { IsString, MinLength, MaxLength, IsEmail, IsOptional, Matches, IsIn, IsObject, IsUUID, ValidateNested } from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export const USERNAME_REGEX = /^[a-z0-9_]{3,20}$/;
export const DISPLAY_NAME_REGEX = /^[a-zA-ZÀ-ÿ0-9]+(([-']|\. ?| )[a-zA-ZÀ-ÿ0-9]+)*$/;

export class RegisterDTO {
  @ApiProperty({ example: 'John Doe', minLength: 2, maxLength: 50 })
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  @Matches(DISPLAY_NAME_REGEX, {
    message: 'Nome de exibição deve conter apenas letras, números e espaços, sem caracteres especiais',
  })
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
  @ApiProperty({ description: 'Backend-issued biometric token (JWT type: biometric)', maxLength: 2048 })
  @IsString()
  @MaxLength(2048)
  readonly biometricToken: string;

  @ApiProperty({ format: 'uuid' })
  @IsUUID('4')
  readonly challengeId: string;

  @ApiProperty({ description: 'Base64 DER ECDSA signature over the exact challenge UTF-8 bytes' })
  @IsString()
  @MaxLength(1024)
  @Matches(/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)$/)
  readonly signature: string;
}

export class BiometricTokenDTO {
  @ApiProperty({ description: 'Backend-issued biometric token (JWT type: biometric)', maxLength: 2048 })
  @IsString()
  @MaxLength(2048)
  readonly biometricToken: string;
}

export class BiometricChallengeDTO {
  @ApiProperty({ maxLength: 2048 })
  @IsString()
  @MaxLength(2048)
  readonly biometricToken: string;

  @ApiProperty({ enum: ['login', 'step_up'] })
  @IsIn(['login', 'step_up'])
  readonly purpose: 'login' | 'step_up';

  @ApiPropertyOptional({ enum: ['biometric_enroll', 'delete_account', 'export_data', 'connect_dashboard', 'cancel_order'] })
  @IsOptional()
  @IsIn(['biometric_enroll', 'delete_account', 'export_data', 'connect_dashboard', 'cancel_order'])
  readonly stepUpPurpose?: 'biometric_enroll' | 'delete_account' | 'export_data' | 'connect_dashboard' | 'cancel_order';

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  readonly resourceId?: string;
}

export class BiometricEnrollmentDTO {
  @ApiProperty({ maxLength: 4096 })
  @IsString()
  @MaxLength(4096)
  readonly stepUpToken: string;

  @ApiProperty({ description: 'Base64 DER SubjectPublicKeyInfo for a P-256 key', maxLength: 1024 })
  @IsString()
  @MaxLength(1024)
  @Matches(/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)$/)
  readonly publicKey: string;
}

export class StepUpProofDTO {
  @ApiProperty({ enum: ['password', 'google', 'apple', 'biometric', 'magic_link'] })
  @IsIn(['password', 'google', 'apple', 'biometric', 'magic_link'])
  readonly kind: 'password' | 'google' | 'apple' | 'biometric' | 'magic_link';

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1024)
  readonly password?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(8192)
  readonly idToken?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(8192)
  readonly identityToken?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(256)
  readonly rawNonce?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(2048)
  readonly biometricToken?: string;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  readonly challengeId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(1024)
  @Matches(/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)$/)
  readonly signature?: string;

  @ApiPropertyOptional({ description: 'Single-use action-confirmation link token; accepted only by web step-up.' })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  readonly token?: string;

  @ApiPropertyOptional({ description: 'Server HMAC binding the token to user, purpose, and resource.' })
  @IsOptional()
  @IsString()
  @Matches(/^[0-9a-f]{64}$/)
  readonly contextSignature?: string;
}

export class StepUpDTO {
  @ApiProperty({ enum: ['biometric_enroll', 'delete_account', 'export_data', 'connect_dashboard', 'cancel_order'] })
  @IsIn(['biometric_enroll', 'delete_account', 'export_data', 'connect_dashboard', 'cancel_order'])
  readonly purpose: 'biometric_enroll' | 'delete_account' | 'export_data' | 'connect_dashboard' | 'cancel_order';

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  readonly resourceId?: string;

  @ApiProperty({ type: StepUpProofDTO })
  @IsObject()
  @ValidateNested()
  @Type(() => StepUpProofDTO)
  readonly proof: StepUpProofDTO;
}

export class GoogleAuthDTO {
  @ApiProperty({ description: 'Google ID token from google_sign_in' })
  @IsString()
  readonly idToken: string;
}

export class AppleAuthDTO {
  @ApiProperty({ description: 'Apple identity token' })
  @IsString()
  @MaxLength(8192)
  readonly identityToken: string;

  @ApiProperty({ description: 'Single-use Apple authorization code' })
  @IsString()
  @MaxLength(4096)
  readonly authorizationCode: string;

  @ApiProperty({ description: 'Original cryptographically random nonce used to request Apple credentials' })
  @IsString()
  @MinLength(32)
  @MaxLength(256)
  readonly rawNonce: string;

  @ApiPropertyOptional({ description: 'Optional display label supplied by Apple on first authorization' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  @MaxLength(50)
  @Matches(DISPLAY_NAME_REGEX)
  @SanitizeText()
  readonly fullName?: string;
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
  @Matches(DISPLAY_NAME_REGEX, {
    message: 'Nome de exibição deve conter apenas letras, números e espaços, sem caracteres especiais',
  })
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
