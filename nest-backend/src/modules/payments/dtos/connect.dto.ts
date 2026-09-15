import { ApiProperty } from '@nestjs/swagger';
import { ConnectStatus } from '../types/connect.types';

export class ConnectStatusOutput {
  @ApiProperty({ enum: ['onboarding-required', 'requirements-due', 'restricted', 'transfer-ready'] })
  readonly status: ConnectStatus;

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
