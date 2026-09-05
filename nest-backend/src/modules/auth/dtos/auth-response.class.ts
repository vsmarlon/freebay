import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserResponse } from '@/modules/users/mappers/user.mapper';

export class AuthSessionResponse {
  @ApiProperty({ type: UserResponse })
  user: UserResponse;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  token: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  refreshToken: string;

  @ApiPropertyOptional({ example: 'eyJhbGciOiJIUzI1NiIs...', description: 'Long-lived biometric token for next biometric login' })
  biometricToken?: string;
}

export class BiometricSessionResponse {
  @ApiProperty({ type: UserResponse })
  user: UserResponse;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  token: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  refreshToken: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...', description: 'Rotated biometric token — store this in the keychain, replacing the previous one' })
  biometricToken: string;
}

export class TokenRefreshResponse {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  token: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  refreshToken: string;
}

export class MessageResponse {
  @ApiProperty({ example: 'Logout realizado' })
  message: string;
}

export class StatusResponse {
  @ApiProperty({ example: true })
  status: boolean;
}
