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

export class GuestSessionResponse {
  @ApiProperty({ example: { id: 'guest-uuid', isGuest: true } })
  user: { id: string; isGuest: boolean };

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIs...' })
  token: string;
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
