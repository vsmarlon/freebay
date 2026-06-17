import { IsInt, IsPositive, IsString, MinLength, MaxLength, IsIn } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

const PIX_KEY_TYPES = ['CPF', 'EMAIL', 'PHONE', 'RANDOM'] as const;

export class WithdrawDTO {
  @ApiProperty({ example: 5000, description: 'Amount in cents' })
  @IsInt()
  @IsPositive()
  amount: number;

  @ApiProperty({ example: 'test@example.com' })
  @IsString()
  @MinLength(1)
  pixKey: string;

  @ApiProperty({ enum: PIX_KEY_TYPES })
  @IsIn(PIX_KEY_TYPES)
  pixKeyType: 'CPF' | 'EMAIL' | 'PHONE' | 'RANDOM';
}

export class BankAccountDTO {
  @ApiProperty({ example: '237' })
  @IsString()
  @MinLength(3)
  bankCode: string;

  @ApiProperty({ example: '12345' })
  @IsString()
  @MinLength(1)
  accountNumber: string;

  @ApiProperty({ example: '1' })
  @IsString()
  @MinLength(1)
  accountCheckDigit: string;

  @ApiProperty({ example: '0001' })
  @IsString()
  @MinLength(1)
  branchNumber: string;

  @ApiProperty({ example: '0' })
  @IsString()
  @MinLength(1)
  branchCheckDigit: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  @MinLength(1)
  holderName: string;

  @ApiProperty({ example: '12345678901' })
  @IsString()
  @MinLength(11)
  @MaxLength(14)
  holderDocument: string;
}

export class WalletResponse {
  @ApiProperty({ example: 100000 })
  balance: number;

  @ApiProperty({ example: 25000 })
  pendingBalance: number;

  @ApiProperty({ example: 75000 })
  availableBalance: number;
}

export class WithdrawalResponse {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: 5000 })
  amount: number;

  @ApiProperty({ example: 'PENDING' })
  status: string;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  createdAt: Date;
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
