import { Test, TestingModule } from '@nestjs/testing';
import { GuestUseCase } from './guest.usecase';

describe('GuestUseCase', () => {
  let sut: GuestUseCase;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [GuestUseCase],
    }).compile();

    sut = module.get<GuestUseCase>(GuestUseCase);
  });

  it('should be defined', () => {
    expect(sut).toBeDefined();
  });

  it('should generate a guest user with guest_ prefix', async () => {
    const result = await sut.execute();

    expect(result.userId).toMatch(/^guest_\d{6}$/);
    expect(result.guestToken).toBeDefined();
  });

  it('should generate unique guest numbers', async () => {
    const result1 = await sut.execute();
    const result2 = await sut.execute();

    expect(result1.userId).not.toBe(result2.userId);
  });
});
