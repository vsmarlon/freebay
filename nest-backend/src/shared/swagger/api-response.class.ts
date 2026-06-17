import { ApiProperty } from '@nestjs/swagger';

export class ApiErrorDetail {
  @ApiProperty({ example: 'VALIDATION_ERROR' })
  code: string;

  @ApiProperty({ example: 'Invalid input' })
  message: string;
}

export class ApiErrorResponse {
  @ApiProperty({ example: false })
  success: boolean;

  @ApiProperty({ type: ApiErrorDetail })
  error: ApiErrorDetail;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  timestamp: string;

  @ApiProperty({ example: '/api/auth/register' })
  path: string;
}
