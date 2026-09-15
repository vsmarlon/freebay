import { CheckUsernameAvailabilityUseCase } from './check-username-availability.usecase';
import { UserDatabaseRepository } from '../data/repositories/user-database.repository';
import { DatabaseError } from '@/shared/core/errors';
import { left, right } from '@/shared/core/either';

describe('CheckUsernameAvailabilityUseCase', () => {
  let sut: CheckUsernameAvailabilityUseCase;
  let mockUserRepository: jest.Mocked<Partial<UserDatabaseRepository>>;

  beforeEach(async () => {
    mockUserRepository = {
      findByUsername: jest.fn().mockResolvedValue(right(null)),
    } as jest.Mocked<Partial<UserDatabaseRepository>>;

    sut = new CheckUsernameAvailabilityUseCase(mockUserRepository as UserDatabaseRepository);
  });

  it('returns available: true when username is not taken', async () => {
    mockUserRepository.findByUsername = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({ username: 'valid_user' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.available).toBe(true);
    }
    expect(mockUserRepository.findByUsername).toHaveBeenCalledWith('valid_user');
  });

  it('returns available: false when username is already taken', async () => {
    mockUserRepository.findByUsername = jest.fn().mockResolvedValue(
      right({
        id: 'existing-id',
        username: 'valid_user',
        displayName: 'Existing User',
      }),
    );

    const result = await sut.execute({ username: 'valid_user' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.available).toBe(false);
    }
  });

  it('normalizes username (lowercase & trimmed) before querying repository', async () => {
    mockUserRepository.findByUsername = jest.fn().mockResolvedValue(right(null));

    const result = await sut.execute({ username: '  Valid_User  ' });

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.available).toBe(true);
    }
    expect(mockUserRepository.findByUsername).toHaveBeenCalledWith('valid_user');
  });

  it('returns available: false for invalid username formats without querying repository', async () => {
    const invalidUsernames = [
      '',
      'ab', // < 3 chars
      'a'.repeat(21), // > 20 chars
      'user name', // contains spaces
      'user@name', // contains special chars
      'user!name',
      'user.name',
    ];

    for (const invalid of invalidUsernames) {
      const result = await sut.execute({ username: invalid });
      expect(result.isRight()).toBe(true);
      if (result.isRight()) {
        expect(result.value.available).toBe(false);
      }
    }

    expect(mockUserRepository.findByUsername).not.toHaveBeenCalled();
  });

  it('returns Left(AppError) when repository fails with a DB error', async () => {
    mockUserRepository.findByUsername = jest
      .fn()
      .mockResolvedValue(left(new DatabaseError('Erro ao buscar usuário por username')));

    const result = await sut.execute({ username: 'valid_user' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) {
      expect(result.value.code).toBe('DB_ERROR');
      expect(result.value.message).toBe('Erro ao buscar usuário por username');
    }
  });
});
