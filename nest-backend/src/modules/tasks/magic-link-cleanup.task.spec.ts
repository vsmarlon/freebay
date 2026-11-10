import { MagicLinkCleanupTask } from './magic-link-cleanup.task';
import { MagicLinkDatabaseRepository } from '../auth/data/repositories/magic-link-database.repository';
import { Test } from '@nestjs/testing';

describe('MagicLinkCleanupTask', () => {
  it('deletes expired links after one day and consumed links after thirty days', async () => {
    const repository = { deleteExpiredOrConsumed: jest.fn().mockResolvedValue({ isRight: () => true, value: 2 }) };
    const module = await Test.createTestingModule({ providers: [MagicLinkCleanupTask, { provide: MagicLinkDatabaseRepository, useValue: repository }] }).compile();
    const task = module.get(MagicLinkCleanupTask);
    const now = new Date('2026-01-31T00:00:00.000Z');
    await task.cleanupMagicLinks(now);
    expect(repository.deleteExpiredOrConsumed).toHaveBeenCalledWith(
      new Date('2026-01-30T00:00:00.000Z'),
      new Date('2026-01-01T00:00:00.000Z'),
    );
  });
});
