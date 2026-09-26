import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { TransactionDatabaseRepository } from '@/modules/payments/data/repositories/transaction-database.repository';
import { PrismaService } from './prisma.service';

// This deliberately bypasses setup-integration.ts: syncing a separate test
// database first would hide drift in the database used by the running app.
describe('Runtime database schema', () => {
  let module: TestingModule;

  beforeAll(async () => {
    const url = new URL(process.env.DATABASE_URL ?? '');
    url.searchParams.set(
      'options',
      `${url.searchParams.get('options') ?? ''} -c default_transaction_read_only=on`,
    );
    module = await Test.createTestingModule({
      providers: [
        PrismaService,
        TransactionDatabaseRepository,
        { provide: ConfigService, useValue: new ConfigService({ DATABASE_URL: url.toString() }) },
      ],
    }).compile();
    await module.init();
    const identity = await module.get(PrismaService).$queryRaw<
      Array<{ database: string; schema: string; read_only: string }>
    >`SELECT current_database() AS database, current_schema() AS schema,
        current_setting('default_transaction_read_only') AS read_only`;
    Logger.log(`Runtime database identity ${JSON.stringify(identity)}`, 'RuntimeSchemaSmoke');
    expect(identity[0].read_only).toBe('on');
  });

  afterAll(async () => { await module?.close(); });

  it('executes the real transfer reconciliation query on the configured database', async () => {
    const result = await module.get(TransactionDatabaseRepository).findTransferFailures(null, 1);
    expect(result.isLeft() ? result.value : null).toBeNull();
  });
});
