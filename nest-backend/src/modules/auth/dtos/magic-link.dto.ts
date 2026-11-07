import { StepUpPurpose } from '@/shared/auth/biometric-credential.service';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Equals, IsBoolean, IsEmail, IsIn, IsOptional, IsString, IsUUID, Length } from 'class-validator';

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

  @ApiProperty({ enum: ['account-deletion'], required: false })
  @IsOptional()
  @IsIn(['account-deletion'])
  purpose?: 'account-deletion';
}

export class ConsumeMagicLinkDTO {
  @ApiProperty({ minLength: 32 })
  @IsString()
  @Length(32, 512)
  token: string;
}

export class RequestStepUpMagicLinkDTO {
  @ApiProperty({ enum: StepUpPurpose })
  @IsIn(Object.values(StepUpPurpose))
  purpose: StepUpPurpose;

  @ApiPropertyOptional({ format: 'uuid' })
  @IsOptional()
  @IsUUID('4')
  resourceId?: string;

  @ApiProperty({ enum: ['pt-BR', 'en'] })
  @IsIn(['pt-BR', 'en'])
  locale: 'pt-BR' | 'en';

  @ApiProperty({ example: true, description: 'Consent to this sensitive-action confirmation email, not marketing.' })
  @IsBoolean()
  @Equals(true)
  consent: true;
}
