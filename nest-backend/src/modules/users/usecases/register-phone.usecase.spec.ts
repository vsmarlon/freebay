import { Test, TestingModule } from '@nestjs/testing';
import { RegisterPhoneUseCase } from './register-phone.usecase';
import { UserDatabaseRepository } from '@/modules/auth/data/repositories/user-database.repository';
import { PhoneVerificationDatabaseRepository } from '../data/repositories/phone-verification-database.repository';
import { SmsService } from '../services/sms.service';
import { right, left } from '@/shared/core/either';
import { DatabaseError } from '@/shared/core/errors';

const mockUserRepository = {
  update: jest.fn(),
};

const mockPhoneVerificationRepository = {
  create: jest.fn(),
  deleteManyForUser: jest.fn(),
  markSent: jest.fn(),
};

const mockSmsService = {
  sendVerificationCode: jest.fn(),
};

describe('RegisterPhoneUseCase', () => {
  let sut: RegisterPhoneUseCase;

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegisterPhoneUseCase,
        { provide: UserDatabaseRepository, useValue: mockUserRepository },
        { provide: PhoneVerificationDatabaseRepository, useValue: mockPhoneVerificationRepository },
        { provide: SmsService, useValue: mockSmsService },
      ],
    }).compile();

    sut = module.get(RegisterPhoneUseCase);

    mockPhoneVerificationRepository.deleteManyForUser.mockResolvedValue(right(undefined));
    mockPhoneVerificationRepository.create.mockResolvedValue(
      right({ id: 'code-1', expiresAt: new Date(Date.now() + 10 * 60 * 1000) }),
    );
    mockUserRepository.update.mockResolvedValue(right({ id: 'user-1' }));
    mockSmsService.sendVerificationCode.mockResolvedValue('sms-provider-id');
    mockPhoneVerificationRepository.markSent.mockResolvedValue(right({ id: 'code-1' }));
  });

  it('rejects an invalid phone number', async () => {
    const result = await sut.execute({ userId: 'user-1', phone: '123' });
    expect(result.isLeft()).toBe(true);
    expect(mockPhoneVerificationRepository.create).not.toHaveBeenCalled();
  });

  it('deletes prior codes before creating a new one', async () => {
    await sut.execute({ userId: 'user-1', phone: '11999999999' });
    expect(mockPhoneVerificationRepository.deleteManyForUser).toHaveBeenCalledWith('user-1');
  });

  it('persists only a hashed code, never the plaintext code', async () => {
    await sut.execute({ userId: 'user-1', phone: '11999999999' });
    const createArgs = mockPhoneVerificationRepository.create.mock.calls[0][0];
    expect(createArgs.codeHash).toBeDefined();
    expect(typeof createArgs.codeHash).toBe('string');
    expect(createArgs.codeHash.length).toBeGreaterThan(6);
    expect(createArgs.expiresAt.getTime()).toBeGreaterThan(Date.now() + 9 * 60 * 1000);
  });

  it('calls SmsService with the plaintext code, and never returns it', async () => {
    const result = await sut.execute({ userId: 'user-1', phone: '11999999999' });

    expect(mockSmsService.sendVerificationCode).toHaveBeenCalledWith(
      '11999999999',
      expect.stringMatching(/^\d{6}$/),
    );

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
  });

  it('sets phoneVerified to false when saving the phone', async () => {
    await sut.execute({ userId: 'user-1', phone: '11999999999' });
    expect(mockUserRepository.update).toHaveBeenCalledWith('user-1', {
      phone: '11999999999',
      phoneVerified: false,
    });
  });

  it('propagates a repository failure', async () => {
    mockPhoneVerificationRepository.create.mockResolvedValue(left(new DatabaseError('fail')));
    const result = await sut.execute({ userId: 'user-1', phone: '11999999999' });
    expect(result.isLeft()).toBe(true);
  });
});
