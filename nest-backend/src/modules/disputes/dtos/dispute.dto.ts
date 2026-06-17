import { IsUUID, IsString, MinLength, IsIn } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Dispute, Order, User, Product, Prisma } from '@prisma/client';
import { SanitizeText } from '@/shared/utils/sanitize.decorator';

export class OpenDisputeDTO {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  @IsUUID()
  orderId: string;

  @ApiProperty({ example: 'Produto não corresponde à descrição' })
  @IsString()
  @MinLength(1)
  @SanitizeText()
  reason: string;
}

export class ResolveDisputeDTO {
  @ApiProperty({ example: 'Buyer received refund' })
  @IsString()
  @MinLength(1)
  @SanitizeText()
  resolution: string;

  @ApiProperty({ enum: ['BUYER', 'SELLER'] })
  @IsIn(['BUYER', 'SELLER'])
  winner: 'BUYER' | 'SELLER';
}

export class OpenDisputeOutput {
  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  id: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  orderId: string;

  @ApiProperty({ example: '550e8400-e29b-41d4-a716-446655440000' })
  openedById: string;

  @ApiProperty({ example: 'Produto não corresponde à descrição' })
  reason: string;

  @ApiProperty({ example: 'OPEN' })
  status: string;

  @ApiProperty({ example: '2026-06-17T12:00:00.000Z' })
  createdAt: Date;

  @ApiProperty({ example: '2026-07-17T12:00:00.000Z' })
  expiresAt: Date;
}

export class SubmitEvidenceOutput {
  @ApiProperty({ example: true })
  submitted: boolean;
}

export class ResolveDisputeOutput {
  @ApiProperty({ example: true })
  resolved: boolean;
}

export interface OpenDisputeInput {
  userId: string;
  orderId: string;
  reason: string;
}

export interface SubmitEvidenceInput {
  disputeId: string;
  userId: string;
  evidence: Prisma.InputJsonValue;
}

export interface ResolveDisputeInput {
  disputeId: string;
  resolution: string;
  winner: 'BUYER' | 'SELLER';
}

export type GetDisputeOutput = Dispute & {
  order: Order & {
    buyer: Pick<User, 'id' | 'displayName' | 'avatarUrl'>;
    seller: Pick<User, 'id' | 'displayName' | 'avatarUrl'>;
    product: Product;
  };
  openedBy: Pick<User, 'id' | 'displayName'>;
};

export type GetUserDisputesOutput = (Dispute & {
  order: Order & {
    product: Product;
  };
})[];
