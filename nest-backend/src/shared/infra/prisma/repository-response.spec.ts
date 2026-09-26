import { Logger } from '@nestjs/common';
import { AppError, DatabaseError } from '@/shared/core/errors';
import { repositoryResponse } from './repository-response';

describe('repositoryResponse', () => {
  it('returns the awaited value', async () => {
    const result = await repositoryResponse(async () => 'ok');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) expect(result.value).toBe('ok');
  });

  it('preserves AppError identity', async () => {
    const error = new AppError('BUSINESS', 'business failure');
    const logger = jest.spyOn(Logger, 'error').mockImplementation();
    const result = await repositoryResponse(async () => { throw error; }, 'business failure', 'TestRepository');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBe(error);
    expect(logger).not.toHaveBeenCalled();
    logger.mockRestore();
  });

  it('logs unknown failures and returns DatabaseError', async () => {
    const logger = jest.spyOn(Logger, 'error').mockImplementation();
    const result = await repositoryResponse(async () => { throw new Error('offline'); }, 'Could not load', 'TestRepository');

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value).toBeInstanceOf(DatabaseError);
      expect(result.value.message).toBe('Could not load');
    }
    expect(logger).toHaveBeenCalledWith('Could not load', expect.any(String), 'TestRepository');
    logger.mockRestore();
  });
});
