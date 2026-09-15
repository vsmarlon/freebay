import { Test } from '@nestjs/testing';
import { AdminController } from './admin.controller';
import { ListReportsUseCase } from './usecases/list-reports.usecase';
import { ResolveReportUseCase } from './usecases/resolve-report.usecase';
import { SuspendUserUseCase } from './usecases/suspend-user.usecase';
import { RemoveContentUseCase } from './usecases/remove-content.usecase';
import { ListModerationActionsUseCase } from './usecases/list-moderation-actions.usecase';
import { ListTransferFailuresUseCase } from './usecases/list-transfer-failures.usecase';
import { JwtAuthGuard } from '@/modules/auth/guards/jwt-auth.guard';

describe('AdminController transfer failures', () => {
  it('forwards cursor pagination to the operator use case', async () => {
    const transferFailures = { execute: jest.fn() };
    const module = await Test.createTestingModule({
      controllers: [AdminController],
      providers: [
        { provide: ListReportsUseCase, useValue: { execute: jest.fn() } },
        { provide: ResolveReportUseCase, useValue: { execute: jest.fn() } },
        { provide: SuspendUserUseCase, useValue: { execute: jest.fn() } },
        { provide: RemoveContentUseCase, useValue: { execute: jest.fn() } },
        { provide: ListModerationActionsUseCase, useValue: { execute: jest.fn() } },
        { provide: ListTransferFailuresUseCase, useValue: transferFailures },
      ],
    }).overrideGuard(JwtAuthGuard).useValue({ canActivate: () => true }).compile();

    await module.get(AdminController).listTransferFailures({ cursor: 'cursor', limit: 10 });

    expect(transferFailures.execute).toHaveBeenCalledWith({ cursor: 'cursor', limit: 10 });
  });
});
