import { Test, TestingModule } from '@nestjs/testing';
import { RegisterFcmTokenUseCase } from './register-fcm-token.usecase';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';

jest.mock('@/shared/infra/prisma/prisma.service');

const mockPrisma = {
  user: {
    update: jest.fn(),
  },
};

describe('RegisterFcmTokenUseCase', () => {
  let sut: RegisterFcmTokenUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        RegisterFcmTokenUseCase,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    sut = module.get<RegisterFcmTokenUseCase>(RegisterFcmTokenUseCase);
    jest.clearAllMocks();
  });

  it('should register FCM token successfully', async () => {
    mockPrisma.user.update.mockResolvedValue({});

    const result = await sut.execute('user-123', 'fcm-token-123');

    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value).toBeUndefined();
    }
    expect(mockPrisma.user.update).toHaveBeenCalledWith({
      where: { id: 'user-123' },
      data: { fcmToken: 'fcm-token-123' },
    });
  });
});
