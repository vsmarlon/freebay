import { IsInt, IsPositive, IsString, MinLength, MaxLength, IsIn } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

const PIX_KEY_TYPES = ['CPF', 'EMAIL', 'PHONE', 'RANDOM'] as const;

export class WithdrawDTO {
  @ApiProperty({ example: 5000, description: 'Amount in cents' })
  @IsInt()
  @IsPositive()
  readonly amount: number;

  @ApiProperty({ example: 'test@example.com' })
  @IsString()
  @MinLength(1)
  readonly pixKey: string;

  @ApiProperty({ enum: PIX_KEY_TYPES })
  @IsIn(PIX_KEY_TYPES)
  readonly pixKeyType: 'CPF' | 'EMAIL' | 'PHONE' | 'RANDOM';
}

export class BankAccountDTO {
  @ApiProperty({ example: '237' })
  @IsString()
  @MinLength(3)
  readonly bankCode: string;

  @ApiProperty({ example: '12345' })
  @IsString()
  @MinLength(1)
  readonly accountNumber: string;

  @ApiProperty({ example: '1' })
  @IsString()
  @MinLength(1)
  readonly accountCheckDigit: string;

  @ApiProperty({ example: '0001' })
  @IsString()
  @MinLength(1)
  readonly branchNumber: string;

  @ApiProperty({ example: '0' })
  @IsString()
  @MinLength(1)
  readonly branchCheckDigit: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  @MinLength(1)
  readonly holderName: string;

  @ApiProperty({ example: '12345678901' })
  @IsString()
  @MinLength(11)
  @MaxLength(14)
  readonly holderDocument: string;
}

export class WalletResponse {
  @ApiProperty({ example: 100000 })
  readonly balance: number;

  @ApiProperty({ example: 25000 })
  readonly pendingBalance: number;

  @ApiProperty({ example: 75000 })
  readonly availableBalance: number;
}

export class WithdrawalResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  readonly id: string;

  @ApiProperty({ example: 5000 })
  readonly amount: number;

  @ApiProperty({ example: 'PENDING' })
  readonly status: string;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  readonly createdAt: Date;
}

export interface GetWalletOutput {
  balance: number;
  pendingBalance: number;
  availableBalance: number;
}

export interface WithdrawInput {
  userId: string;
  amount: number;
  pixKey: string;
  pixKeyType: 'CPF' | 'EMAIL' | 'PHONE' | 'RANDOM';
}
