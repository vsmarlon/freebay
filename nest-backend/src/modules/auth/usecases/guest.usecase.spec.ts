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
    expect(result.isRight()).toBe(true);
    if (result.isRight()) {
      expect(result.value.userId).toMatch(/^guest_\d{6}$/);
      expect(result.value.guestToken).toBeDefined();
    }
  });

  it('should generate unique guest numbers', async () => {
    const result1 = await sut.execute();
    const result2 = await sut.execute();
    expect(result1.isRight()).toBe(true);
    expect(result2.isRight()).toBe(true);
    if (result1.isRight() && result2.isRight()) {
      expect(result1.value.userId).not.toBe(result2.value.userId);
    }
  });
});
