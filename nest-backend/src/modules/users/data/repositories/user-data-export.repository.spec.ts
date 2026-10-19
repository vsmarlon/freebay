import { Test } from '@nestjs/testing';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { CpfProtectionService } from '@/shared/utils/cpf-protection.service';
import { UserDataExportRepository } from './user-data-export.repository';

const list = () => jest.fn().mockResolvedValue([]);
const cpfProtection = new CpfProtectionService(new ConfigService({
  CPF_ENCRYPTION_KEY: Buffer.alloc(32, 1).toString('base64'),
  CPF_HMAC_KEY: Buffer.alloc(32, 2).toString('base64'),
}));

describe('UserDataExportRepository', () => {
  it('queries exported records through explicit privacy allowlists', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue({ id: 'u1', cpf: cpfProtection.protect('52998224725').cpf }) },
      product: { findMany: list() },
      post: { findMany: list() },
      comment: { findMany: list() },
      order: { findMany: list() },
      transaction: { findMany: list() },
      walletEntry: { findMany: list() },
      wallet: { findUnique: jest.fn().mockResolvedValue(null) },
      connectAccount: { findUnique: jest.fn().mockResolvedValue(null) },
      review: { findMany: list() },
      directMessage: { findMany: list() },
      chatMessage: { findMany: list() },
      notification: { findMany: list() },
      report: { findMany: list() },
      dispute: { findMany: list() },
      follow: { findMany: list() },
      block: { findMany: list() },
      story: { findMany: list() },
      savedPost: { findMany: list() },
      like: { findMany: list() },
      share: { findMany: list() },
      favorite: { findMany: list() },
      cartItem: { findMany: list() },
    };
    const module = await Test.createTestingModule({
      providers: [UserDataExportRepository, { provide: CpfProtectionService, useValue: cpfProtection }, { provide: PrismaService, useValue: prisma }],
    }).compile();

    const result = await module.get(UserDataExportRepository).exportData('u1');

    expect(result.isRight()).toBe(true);
    if (result.isRight() && result.value) expect(result.value.profile.cpf).toBe('52998224725');
    for (const query of [
      prisma.product.findMany, prisma.post.findMany, prisma.comment.findMany,
      prisma.order.findMany, prisma.transaction.findMany, prisma.walletEntry.findMany,
      prisma.review.findMany, prisma.directMessage.findMany, prisma.chatMessage.findMany,
      prisma.notification.findMany, prisma.report.findMany, prisma.dispute.findMany,
      prisma.story.findMany, prisma.savedPost.findMany, prisma.like.findMany,
      prisma.share.findMany, prisma.favorite.findMany, prisma.cartItem.findMany,
    ]) {
      expect(query).toHaveBeenCalledWith(expect.objectContaining({ select: expect.any(Object) }));
    }
    expect(prisma.wallet.findUnique).toHaveBeenCalledWith(expect.objectContaining({ select: expect.any(Object) }));
    expect(prisma.user.findUnique).toHaveBeenCalledWith(expect.objectContaining({
      select: expect.not.objectContaining({ appleId: true, appleRefreshTokenEncrypted: true, googleId: true, passwordHash: true }),
    }));
    expect(prisma.transaction.findMany).toHaveBeenCalledWith(expect.objectContaining({
      select: expect.not.objectContaining({ externalId: true, idempotencyKey: true, transferLastError: true }),
    }));
    expect(prisma.report.findMany).toHaveBeenCalledWith(expect.objectContaining({
      select: expect.not.objectContaining({ status: true, reviewedById: true, hideFromUser: true }),
    }));
  });
});
