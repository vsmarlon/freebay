import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsUrl,
  IsObject,
  IsInt,
  Min,
  Max,
  Matches,
  Validate,
  ValidatorConstraint,
  ValidatorConstraintInterface,
  IsNotEmpty,
  IsIn,
  IsUUID,
  ValidateIf,
} from 'class-validator';
import { Type, Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { isValidCpfOrCnpj } from '@/shared/utils/cpf.utils';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';
import { USERNAME_REGEX, DISPLAY_NAME_REGEX } from '@/modules/auth/dtos/auth.dto';

@ValidatorConstraint({ name: 'cpfOrCnpj', async: false })
export class IsCpfOrCnpjConstraint implements ValidatorConstraintInterface {
  validate(value: string) {
    return isValidCpfOrCnpj(value);
  }

  defaultMessage() {
    return 'CPF ou CNPJ inválido';
  }
}

export class UpdateProfileDTO {
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

  @ApiPropertyOptional({ example: 'john_doe', minLength: 3, maxLength: 20, description: '3-20 chars, lowercase letters/numbers/underscore only' })
  @IsOptional()
  @IsString()
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  @Matches(USERNAME_REGEX, { message: 'Nome de usuário deve ter 3-20 caracteres e conter apenas letras minúsculas, números e underscore' })
  readonly username?: string;

  @ApiPropertyOptional({ example: 'Bio text here...', maxLength: 150 })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  @SanitizeText()
  readonly bio?: string;

  @ApiPropertyOptional({ example: 'São Paulo' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  readonly city?: string;

  @ApiPropertyOptional({ example: 'SP' })
  @IsOptional()
  @IsString()
  readonly state?: string;

  @ApiPropertyOptional({ example: 'https://example.com/avatar.jpg' })
  @IsOptional()
  @IsUrl()
  readonly avatarUrl?: string;

  @ApiPropertyOptional({ example: '529.982.247-25' })
  @IsOptional()
  @Validate(IsCpfOrCnpjConstraint)
  readonly cpf?: string;
}

export class RegisterPhoneDTO {
  @ApiProperty({ example: '11999999999' })
  @IsString()
  @IsNotEmpty()
  readonly phone: string;
}

export class VerifyPhoneDTO {
  @ApiProperty({ example: '123456' })
  @IsString()
  readonly code: string;
}

@ValidatorConstraint({ name: 'notificationPreferences', async: false })
export class NotificationPreferencesConstraint implements ValidatorConstraintInterface {
  validate(value: unknown): boolean {
    return value !== null && typeof value === 'object' && !Array.isArray(value) &&
      Object.entries(value).every(([key, enabled]) =>
        ['orders', 'follows', 'messages', 'disputes'].includes(key) && typeof enabled === 'boolean');
  }

  defaultMessage() { return 'Preferências de notificação inválidas'; }
}

export class UpdateFcmTokenDTO {
  @ApiPropertyOptional({ example: 'fcm-token-value' })
  @IsOptional()
  @IsString()
  @MinLength(1)
  @MaxLength(4096)
  readonly fcmToken?: string | null;

  @ApiPropertyOptional({ description: 'Stable UUID of this app installation; required when setting or removing a token' })
  @ValidateIf((input: UpdateFcmTokenDTO) => input.fcmToken !== undefined || input.installationId !== undefined)
  @IsUUID('4')
  readonly installationId?: string;

  @ApiPropertyOptional({ example: { orders: true, follows: true, messages: true } })
  @IsOptional()
  @IsObject()
  @Validate(NotificationPreferencesConstraint)
  readonly notificationPrefs?: Record<string, boolean>;
}

export class OffsetPaginationQueryDTO {
  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly offset?: number;
}

export class CloseFriendCandidatesQueryDTO extends OffsetPaginationQueryDTO {
  @ApiPropertyOptional({ description: 'Search followers by name or username' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  readonly q?: string;

  @ApiPropertyOptional({ enum: ['true'], description: 'Show only selected friends' })
  @IsOptional()
  @IsIn(['true'])
  readonly selected?: string;
}

export class UserSearchQueryDTO {
  @ApiPropertyOptional({ description: 'Search query' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  readonly q?: string;

  @ApiPropertyOptional({ example: 0 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  readonly offset?: number;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;
}

export class SuggestionsQueryDTO {
  @ApiPropertyOptional({ example: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  readonly limit?: number;
}

export interface GetProfileInput {
  userId: string;
  viewerId?: string;
  includePrivate?: boolean;
}

export interface GetUserStatsInput {
  userId: string;
}

export interface UpdateProfileInput extends UpdateProfileDTO {
  userId: string;
}

export interface UpdateFcmTokenInput extends UpdateFcmTokenDTO {
  userId: string;
}

export interface FollowUserInput {
  followerId: string;
  followingId: string;
}

export interface BlockUserInput {
  blockerId: string;
  blockedId: string;
}

export interface SearchUsersInput {
  query: string;
  limit: number;
  offset: number;
  viewerId?: string;
}

export interface GetSuggestionsInput {
  userId: string;
  limit: number;
}
