import { ApiProperty } from '@nestjs/swagger';

export class ConnectStatusOutput {
  @ApiProperty({ example: false })
  readonly onboarded: boolean;

  @ApiProperty({ example: false })
  readonly transfersEnabled: boolean;

  @ApiProperty({ example: false })
  readonly payoutsEnabled: boolean;

  @ApiProperty({ example: [], type: [String] })
  readonly requirementsDue: string[];
}

export class ConnectOnboardingOutput {
  @ApiProperty({ example: 'https://connect.stripe.com/setup/...' })
  readonly onboardingUrl: string;
}

export class ConnectDashboardOutput {
  @ApiProperty({ example: 'https://connect.stripe.com/express/...' })
  readonly dashboardUrl: string;
}
