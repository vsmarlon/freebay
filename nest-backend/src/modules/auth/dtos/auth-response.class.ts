import { ApiProperty } from '@nestjs/swagger';
import { UserResponse } from '@/modules/users/mappers/user.mapper';

export class AuthSessionResponse {
  @ApiProperty({ type: UserResponse })
  user: UserResponse;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  token: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  refreshToken: string;

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

export class BiometricEnrollmentResponse {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
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
