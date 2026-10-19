import { Test } from '@nestjs/testing';
import { right } from '@/shared/core/either';
import { AccountLifecycleDatabaseRepository } from '@/modules/users/data/repositories/account-lifecycle-database.repository';
import { AccountDeletionTask } from './account-deletion.task';

describe('AccountDeletionTask', () => {
  afterEach(() => jest.useRealTimers());

  it('passes the grace cutoff into the claim and does not report pending media as complete', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-10-09T12:00:00.000Z'));
    const repository = {
      findPurgeCandidates: jest.fn().mockResolvedValue(right([{ id: 'user-1' }])),
      purge: jest.fn().mockResolvedValue(right('pending-media')),
    };
    const module = await Test.createTestingModule({
      providers: [AccountDeletionTask, { provide: AccountLifecycleDatabaseRepository, useValue: repository }],
    }).compile();
    const task = module.get(AccountDeletionTask);
    const warning = jest.spyOn(task['logger'], 'warn').mockImplementation();
    const log = jest.spyOn(task['logger'], 'log').mockImplementation();

    await task.purgeExpiredDeletionRequests();

    const purgeBefore = new Date('2026-10-09T12:00:00.000Z');
    purgeBefore.setDate(purgeBefore.getDate() - 30);
    expect(repository.findPurgeCandidates).toHaveBeenCalledWith(purgeBefore);
    expect(repository.purge).toHaveBeenCalledWith('user-1', purgeBefore, new Date('2026-10-09T12:00:00.000Z'));
    expect(warning).toHaveBeenCalledWith(expect.stringContaining('pending media'));
    expect(log).not.toHaveBeenCalledWith(expect.stringContaining('personal purge scope completed'));
  });

  it('does not claim a canceled candidate was purged', async () => {
    const repository = {
      findPurgeCandidates: jest.fn().mockResolvedValue(right([{ id: 'user-1' }])),
      purge: jest.fn().mockResolvedValue(right('canceled')),
    };
    const module = await Test.createTestingModule({
      providers: [AccountDeletionTask, { provide: AccountLifecycleDatabaseRepository, useValue: repository }],
    }).compile();
    const task = module.get(AccountDeletionTask);
    const log = jest.spyOn(task['logger'], 'log').mockImplementation();

    await task.purgeExpiredDeletionRequests();

    expect(log).not.toHaveBeenCalledWith(expect.stringContaining('personal purge scope completed'));
  });

  it('does not claim unresolved retention review was purged', async () => {
    const repository = {
      findPurgeCandidates: jest.fn().mockResolvedValue(right([{ id: 'user-1' }])),
      purge: jest.fn().mockResolvedValue(right('pending-review')),
    };
    const module = await Test.createTestingModule({
      providers: [AccountDeletionTask, { provide: AccountLifecycleDatabaseRepository, useValue: repository }],
    }).compile();
    const task = module.get(AccountDeletionTask);
    const warning = jest.spyOn(task['logger'], 'warn').mockImplementation();
    const log = jest.spyOn(task['logger'], 'log').mockImplementation();

    await task.purgeExpiredDeletionRequests();

    expect(warning).toHaveBeenCalledWith(expect.stringContaining('retention review'));
    expect(log).not.toHaveBeenCalledWith(expect.stringContaining('personal purge scope completed'));
  });

  it('reports only the approved personal scope as complete', async () => {
    const repository = {
      findPurgeCandidates: jest.fn().mockResolvedValue(right([{ id: 'user-1' }])),
      purge: jest.fn().mockResolvedValue(right('completed')),
    };
    const module = await Test.createTestingModule({
      providers: [AccountDeletionTask, { provide: AccountLifecycleDatabaseRepository, useValue: repository }],
    }).compile();
    const task = module.get(AccountDeletionTask);
    const log = jest.spyOn(task['logger'], 'log').mockImplementation();

    await task.purgeExpiredDeletionRequests();

    expect(log).toHaveBeenCalledWith(expect.stringContaining('Approved personal purge scope completed'));
  });
});
