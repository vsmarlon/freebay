import {
  IsString,
  MinLength,
  MaxLength,
  IsOptional,
  IsUrl,
  IsObject,
  Validate,
  ValidatorConstraint,
  ValidatorConstraintInterface,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { isValidCpfOrCnpj } from '@/shared/utils/cpf.utils';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

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
  @SanitizeText()
  displayName?: string;

  @ApiPropertyOptional({ example: 'Bio text here...', maxLength: 150 })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  @SanitizeText()
  bio?: string;

  @ApiPropertyOptional({ example: 'São Paulo' })
  @IsOptional()
  @IsString()
  @SanitizeText()
  city?: string;

  @ApiPropertyOptional({ example: 'SP' })
  @IsOptional()
  @IsString()
  state?: string;

  @ApiPropertyOptional({ example: 'https://example.com/avatar.jpg' })
  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  @ApiPropertyOptional({ example: '529.982.247-25' })
  @IsOptional()
  @Validate(IsCpfOrCnpjConstraint)
  cpf?: string;
}

export class UpdateFcmTokenDTO {
  @ApiPropertyOptional({ example: 'fcm-token-value' })
  @IsOptional()
  @IsString()
  fcmToken?: string;

  @ApiPropertyOptional({ example: { orders: true, follows: true, messages: true } })
  @IsOptional()
  @IsObject()
  notificationPrefs?: Record<string, boolean>;
}

export interface GetProfileInput {
  userId: string;
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
  cursor?: string;
}

export interface GetSuggestionsInput {
  userId: string;
  limit: number;
}
