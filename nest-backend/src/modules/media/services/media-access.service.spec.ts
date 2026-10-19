import { createHash } from 'crypto';
import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { MediaAccessService } from './media-access.service';

describe('MediaAccessService view-once authorization', () => {
  const openingKey = '550e8400-e29b-41d4-a716-446655440000';
  const hash = createHash('sha256').update(openingKey).digest('hex');

  it('requires the opening key for the recipient and denies sender, wrong key, and closed claims', async () => {
    let closedAt: Date | null = null;
    const findFirst = jest.fn().mockImplementation(async () => ({
      deletedAt: null,
      viewOnce: true,
      readAt: new Date(),
      viewOnceOpeningHash: hash,
      viewOnceClosedAt: closedAt,
      senderId: 'sender-1',
      conversation: { user1Id: 'sender-1', user2Id: 'recipient-1' },
    }));
    const module = await Test.createTestingModule({
      providers: [MediaAccessService, { provide: PrismaService, useValue: { directMessage: { findFirst } } }],
    }).compile();
    const service = module.get(MediaAccessService);

    expect(await service.canRead('recipient-1', 'chat', 'media.jpg')).toBe(false);
    expect(await service.canRead('recipient-1', 'chat', 'media.jpg', openingKey)).toBe(true);
    expect(await service.canRead('recipient-1', 'chat', 'media.jpg', '550e8400-e29b-41d4-a716-446655440001')).toBe(false);
    expect(await service.canRead('sender-1', 'chat', 'media.jpg', openingKey)).toBe(false);
    closedAt = new Date();
    expect(await service.canRead('recipient-1', 'chat', 'media.jpg', openingKey)).toBe(false);
  });
});
