import { ApiProperty } from '@nestjs/swagger';

export class WalletResponse {
  @ApiProperty({ example: 100000 })
  readonly balance: number;

  @ApiProperty({ example: 25000 })
  readonly pendingBalance: number;

  @ApiProperty({ example: 75000 })
  readonly availableBalance: number;
}

export interface GetWalletOutput {
  balance: number;
  pendingBalance: number;
  availableBalance: number;
}
