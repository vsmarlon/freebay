import { left } from '@/shared/core/either';
import { BadRequestError } from '@/shared/core/errors';
import { Test } from '@nestjs/testing';
import { NotificationService } from '@/modules/notifications/services/notification.service';
import { QuoteDatabaseRepository } from '../data/repositories/quote-database.repository';
import { CreateQuoteUseCase } from './create-quote.usecase';

describe('CreateQuoteUseCase', () => {
  it('canonicalizes mention order/duplicates before persisting the request digest', async () => {
    const quoteRepository = { create: jest.fn().mockResolvedValue(left(new BadRequestError())) };
    const notifications = { deliverPersisted: jest.fn() };
    const module = await Test.createTestingModule({ providers: [
      CreateQuoteUseCase,
      { provide: QuoteDatabaseRepository, useValue: quoteRepository },
      { provide: NotificationService, useValue: notifications },
    ] }).compile();
    const sut = module.get(CreateQuoteUseCase);

    const first = await sut.execute({ userId: 'author', content: '  hello  ', sourcePostId: 'source', mentionIds: ['b', 'a', 'b'] });
    const second = await sut.execute({ userId: 'author', content: 'hello', sourcePostId: 'source', mentionIds: ['a', 'b'] });

    expect(first.isLeft()).toBe(true);
    expect(second.isLeft()).toBe(true);
    const firstDigest = quoteRepository.create.mock.calls[0][0].digest;
    const secondDigest = quoteRepository.create.mock.calls[1][0].digest;
    expect(firstDigest).toBe(secondDigest);
    expect(quoteRepository.create.mock.calls[0][0].mentionIds).toEqual(['a', 'b']);
  });

  it('rejects a request without exactly one source before persistence', async () => {
    const quoteRepository = { create: jest.fn() };
    const module = await Test.createTestingModule({ providers: [
      CreateQuoteUseCase,
      { provide: QuoteDatabaseRepository, useValue: quoteRepository },
      { provide: NotificationService, useValue: { deliverPersisted: jest.fn() } },
    ] }).compile();
    const sut = module.get(CreateQuoteUseCase);

    const result = await sut.execute({ userId: 'author', content: 'hello' });

    expect(result.isLeft()).toBe(true);
    if (result.isLeft()) expect(result.value).toBeInstanceOf(BadRequestError);
    expect(quoteRepository.create).not.toHaveBeenCalled();
  });
});
