import { Test } from '@nestjs/testing';
import { prisma } from '../../../../../test/setup-integration';
import { PrismaService } from '@/shared/infra/prisma/prisma.service';
import { AuthSessionStateDatabaseRepository } from '@/shared/infra/prisma/auth-session-state-database.repository';
import { AccountLifecycleDatabaseRepository } from './account-lifecycle-database.repository';

describe('AccountLifecycleDatabaseRepository personal purge integration', () => {
  let repository: AccountLifecycleDatabaseRepository;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      providers: [
        AccountLifecycleDatabaseRepository,
        { provide: PrismaService, useValue: prisma },
        { provide: AuthSessionStateDatabaseRepository, useValue: {} },
      ],
    }).compile();
    repository = module.get(AccountLifecycleDatabaseRepository);
  });

  it('rechecks cancellation and preserves an order-linked listing and every financial row exactly', async () => {
    const suffix = `${Date.now()}-${Math.random()}`;
    const seller = await prisma.user.create({ data: {
      email: `purge-seller-${suffix}@example.test`, displayName: 'Purge seller', deletionRequestedAt: new Date('2026-01-01T00:00:00.000Z'),
      avatarUrl: '/synthetic/avatar.png', bannerUrl: '/synthetic/banner.png', webConsentIp: '192.0.2.1', webConsentUserAgent: 'synthetic',
    } });
    const buyer = await prisma.user.create({ data: { email: `purge-buyer-${suffix}@example.test`, displayName: 'Purge buyer' } });
    const product = await prisma.product.create({ data: {
      sellerId: seller.id, title: 'Synthetic preserved listing', description: 'Financial reference', price: 12345, condition: 'NEW',
    } });
    const productImage = await prisma.productImage.create({ data: { productId: product.id, url: '/synthetic/order-product.png' } });
    const personalListing = await prisma.product.create({ data: {
      sellerId: seller.id, title: 'Personal listing title', description: 'Personal listing description', price: 54321, condition: 'USED', quantity: 4, soldCount: 1,
    } });
    const personalListingImage = await prisma.productImage.create({ data: { productId: personalListing.id, url: '/synthetic/personal-listing.png', blurHash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH' } });
    const order = await prisma.order.create({ data: {
      buyerId: buyer.id, sellerId: seller.id, productId: product.id, quantity: 1, amount: 12345, platformFee: 1234, sellerAmount: 11111,
    } });
    const transaction = await prisma.transaction.create({ data: {
      orderId: order.id, amount: 12345, platformFee: 1234, sellerAmount: 11111, paymentMethod: 'PIX', provider: 'STRIPE', idempotencyKey: `purge-${suffix}`,
    } });
    const wallet = await prisma.wallet.create({ data: { userId: seller.id, availableBalance: 11111, pendingBalance: 0, totalEarned: 11111 } });
    const walletEntry = await prisma.walletEntry.create({ data: {
      userId: seller.id, kind: 'AVAILABLE', amount: 11111, reason: 'SALE_RELEASED', orderId: order.id,
    } });
    const dispute = await prisma.dispute.create({ data: {
      orderId: order.id, openedById: buyer.id, reason: 'synthetic dispute', expiresAt: new Date('2027-01-01T00:00:00.000Z'),
    } });
    const review = await prisma.review.create({ data: {
      reviewerId: seller.id, reviewedId: buyer.id, orderId: order.id, type: 'SELLER_REVIEWING_BUYER', score: 5, comment: 'preserve financial evidence',
    } });
    const reviewImage = await prisma.reviewImage.create({ data: { reviewId: review.id, url: '/synthetic/review.png' } });
    const post = await prisma.post.create({ data: { userId: seller.id, type: 'REGULAR', content: 'private authored text', imageUrl: '/synthetic/post.png' } });
    const parentComment = await prisma.comment.create({ data: { userId: seller.id, postId: post.id, content: 'authored comment' } });
    const reply = await prisma.comment.create({ data: { userId: buyer.id, postId: post.id, parentId: parentComment.id, content: 'third-party reply' } });
    const socialPost = await prisma.post.create({ data: { userId: buyer.id, type: 'REGULAR', content: 'counter regression', likesCount: 2, sharesCount: 2, commentsCount: 4 } });
    await prisma.like.createMany({ data: [{ userId: seller.id, postId: socialPost.id }, { userId: buyer.id, postId: socialPost.id }] });
    await prisma.share.createMany({ data: [{ userId: seller.id, postId: socialPost.id }, { userId: buyer.id, postId: socialPost.id }] });
    const visibleParent = await prisma.comment.create({ data: { userId: seller.id, postId: socialPost.id, content: 'visible parent' } });
    const visibleReply = await prisma.comment.create({ data: { userId: buyer.id, postId: socialPost.id, parentId: visibleParent.id, content: 'preserved reply' } });
    const visibleLeaf = await prisma.comment.create({ data: { userId: seller.id, postId: socialPost.id, content: 'visible leaf' } });
    const otherComment = await prisma.comment.create({ data: { userId: buyer.id, postId: socialPost.id, content: 'comment likes' , likesCount: 2 } });
    await prisma.commentLike.createMany({ data: [{ userId: seller.id, commentId: otherComment.id }, { userId: buyer.id, commentId: otherComment.id }] });
    const message = await prisma.chatMessage.create({ data: { orderId: order.id, senderId: seller.id, content: 'authored order message', attachmentUrl: '/synthetic/chat.png' } });
    const media = await prisma.story.create({ data: {
      userId: seller.id, imageUrl: '/synthetic/story.png', expiresAt: new Date('2027-01-01T00:00:00.000Z'), caption: 'story caption',
    } });
    const preservedBefore = {
      order: await prisma.order.findUniqueOrThrow({ where: { id: order.id } }),
      transaction: await prisma.transaction.findUniqueOrThrow({ where: { id: transaction.id } }),
      wallet: await prisma.wallet.findUniqueOrThrow({ where: { id: wallet.id } }),
      walletEntry: await prisma.walletEntry.findUniqueOrThrow({ where: { id: walletEntry.id } }),
      dispute: await prisma.dispute.findUniqueOrThrow({ where: { id: dispute.id } }),
      review: await prisma.review.findUniqueOrThrow({ where: { id: review.id } }),
      reviewImage: await prisma.reviewImage.findUniqueOrThrow({ where: { id: reviewImage.id } }),
      product: await prisma.product.findUniqueOrThrow({ where: { id: product.id } }),
      productImage: await prisma.productImage.findUniqueOrThrow({ where: { id: productImage.id } }),
    };
    const cutoff = new Date('2026-02-01T00:00:00.000Z');

    const candidates = await repository.findPurgeCandidates(cutoff);
    await prisma.user.update({ where: { id: seller.id }, data: { deletionRequestedAt: null } });
    const canceled = await repository.purge(seller.id, cutoff, new Date('2026-02-02T00:00:00.000Z'));

    expect(candidates.isRight() && candidates.value.some(({ id }) => id === seller.id)).toBe(true);
    expect(canceled.isRight() && canceled.value).toBe('canceled');
    expect(await prisma.user.findUniqueOrThrow({ where: { id: seller.id } })).toEqual(expect.objectContaining({
      deletionRequestedAt: null, avatarUrl: '/synthetic/avatar.png',
    }));

    await prisma.user.update({ where: { id: seller.id }, data: { deletionRequestedAt: new Date('2026-01-01T00:00:00.000Z') } });
    const purged = await repository.purge(seller.id, cutoff, new Date('2026-02-03T00:00:00.000Z'));

    expect(purged.isRight() && purged.value).toBe('pending-media');
    expect(await prisma.user.findUniqueOrThrow({ where: { id: seller.id } })).toEqual(expect.objectContaining({
      avatarUrl: null,
      webConsentIp: null,
      webConsentUserAgent: null,
      personalPurgePendingMedia: expect.arrayContaining([
        '/synthetic/avatar.png', '/synthetic/banner.png', '/synthetic/post.png', '/synthetic/story.png', '/synthetic/chat.png', '/synthetic/personal-listing.png',
      ]),
      personalPurgeCompletedAt: null,
    }));
    expect(await prisma.comment.findUniqueOrThrow({ where: { id: parentComment.id } })).toEqual(expect.objectContaining({ content: '', deletedAt: null }));
    expect(await prisma.comment.findUniqueOrThrow({ where: { id: reply.id } })).toEqual(expect.objectContaining({ content: 'third-party reply', parentId: parentComment.id }));
    expect(await prisma.comment.findUniqueOrThrow({ where: { id: visibleParent.id } })).toEqual(expect.objectContaining({ content: '', deletedAt: null }));
    expect(await prisma.comment.findUniqueOrThrow({ where: { id: visibleReply.id } })).toEqual(expect.objectContaining({ content: 'preserved reply', parentId: visibleParent.id }));
    expect(await prisma.comment.findUniqueOrThrow({ where: { id: visibleLeaf.id } })).toEqual(expect.objectContaining({ content: '', deletedAt: expect.any(Date) }));
    expect(await prisma.post.findUniqueOrThrow({ where: { id: socialPost.id } })).toEqual(expect.objectContaining({ likesCount: 1, sharesCount: 1, commentsCount: 3 }));
    expect(await prisma.comment.findUniqueOrThrow({ where: { id: otherComment.id } })).toEqual(expect.objectContaining({ likesCount: 1 }));
    expect(await prisma.product.findUniqueOrThrow({ where: { id: personalListing.id } })).toEqual(expect.objectContaining({
      title: 'Anúncio removido', description: '', price: 54321, quantity: 4, soldCount: 1,
    }));
    expect(await prisma.productImage.findUniqueOrThrow({ where: { id: personalListingImage.id } })).toEqual(expect.objectContaining({ url: '', blurHash: null }));
    expect(await prisma.chatMessage.findUniqueOrThrow({ where: { id: message.id } })).toEqual(expect.objectContaining({ content: null, attachmentUrl: null, deletedAt: expect.any(Date) }));
    expect(await prisma.story.findUniqueOrThrow({ where: { id: media.id } })).toEqual(expect.objectContaining({ imageUrl: '', caption: null, deletedAt: expect.any(Date) }));
    expect({
      order: await prisma.order.findUniqueOrThrow({ where: { id: order.id } }),
      transaction: await prisma.transaction.findUniqueOrThrow({ where: { id: transaction.id } }),
      wallet: await prisma.wallet.findUniqueOrThrow({ where: { id: wallet.id } }),
      walletEntry: await prisma.walletEntry.findUniqueOrThrow({ where: { id: walletEntry.id } }),
      dispute: await prisma.dispute.findUniqueOrThrow({ where: { id: dispute.id } }),
      review: await prisma.review.findUniqueOrThrow({ where: { id: review.id } }),
      reviewImage: await prisma.reviewImage.findUniqueOrThrow({ where: { id: reviewImage.id } }),
      product: await prisma.product.findUniqueOrThrow({ where: { id: product.id } }),
      productImage: await prisma.productImage.findUniqueOrThrow({ where: { id: productImage.id } }),
    }).toEqual(preservedBefore);

    const countsBeforeRetry = {
      post: await prisma.post.findUniqueOrThrow({ where: { id: socialPost.id }, select: { likesCount: true, sharesCount: true, commentsCount: true } }),
      comment: await prisma.comment.findUniqueOrThrow({ where: { id: otherComment.id }, select: { likesCount: true } }),
    };
    const retry = await repository.purge(seller.id, cutoff, new Date('2026-02-04T00:00:00.000Z'));
    expect(retry.isRight() && retry.value).toBe('pending-media');
    expect({
      post: await prisma.post.findUniqueOrThrow({ where: { id: socialPost.id }, select: { likesCount: true, sharesCount: true, commentsCount: true } }),
      comment: await prisma.comment.findUniqueOrThrow({ where: { id: otherComment.id }, select: { likesCount: true } }),
    }).toEqual(countsBeforeRetry);
  });

  it('withholds completion and preserves listing context for a third-party inquiry', async () => {
    const suffix = `${Date.now()}-${Math.random()}`;
    const seller = await prisma.user.create({ data: {
      email: `purge-inquiry-seller-${suffix}@example.test`, displayName: 'Purge inquiry seller', deletionRequestedAt: new Date('2026-01-01T00:00:00.000Z'),
    } });
    const buyer = await prisma.user.create({ data: { email: `purge-inquiry-buyer-${suffix}@example.test`, displayName: 'Purge inquiry buyer' } });
    const product = await prisma.product.create({ data: {
      sellerId: seller.id, title: 'Inquiry context title', description: 'Keep for third-party conversation', price: 9000, condition: 'USED',
    } });
    const image = await prisma.productImage.create({ data: { productId: product.id, url: '/synthetic/inquiry.png' } });
    await prisma.directConversation.create({ data: { user1Id: buyer.id, user2Id: seller.id, productId: product.id } });

    const result = await repository.purge(seller.id, new Date('2026-02-01T00:00:00.000Z'), new Date('2026-02-02T00:00:00.000Z'));

    expect(result.isRight() && result.value).toBe('pending-verification');
    expect(await prisma.user.findUniqueOrThrow({ where: { id: seller.id } })).toEqual(expect.objectContaining({ personalPurgeCompletedAt: null }));
    expect(await prisma.product.findUniqueOrThrow({ where: { id: product.id } })).toEqual(expect.objectContaining({
      title: 'Inquiry context title', description: 'Keep for third-party conversation', price: 9000,
    }));
    expect(await prisma.productImage.findUniqueOrThrow({ where: { id: image.id } })).toEqual(expect.objectContaining({ url: '/synthetic/inquiry.png' }));
  });
});
