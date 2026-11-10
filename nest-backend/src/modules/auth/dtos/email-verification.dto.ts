import { IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RequestEmailVerificationDTO {
  @ApiPropertyOptional({ enum: ['pt-BR', 'en'], example: 'pt-BR' })
  @IsOptional()
  @IsIn(['pt-BR', 'en'])
  readonly locale?: 'pt-BR' | 'en';
}

export class ConfirmEmailVerificationDTO {
  @ApiProperty({ example: 'token-from-verify-email-link', description: 'Token from the verification email link' })
  @IsString()
  @IsNotEmpty()
  readonly token: string;
}
