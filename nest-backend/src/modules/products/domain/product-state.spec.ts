import { ProductPauseReason, ProductStatus } from '@prisma/client';
import {
  canDeleteProduct,
  canEditProduct,
  canResumeProduct,
  canSetQuantity,
  isReservationHold,
} from './product-state';

describe('product pause reasons', () => {
  it('treats a reservation hold as an open-order claim', () => {
    expect(isReservationHold({ status: ProductStatus.PAUSED, pauseReason: ProductPauseReason.RESERVED })).toBe(true);
    expect(isReservationHold({ status: ProductStatus.PAUSED, pauseReason: ProductPauseReason.SELLER })).toBe(false);
    expect(isReservationHold({ status: ProductStatus.ACTIVE, pauseReason: null })).toBe(false);
  });

  it('blocks editing and deletion only while an order holds the unit', () => {
    expect(canEditProduct({ pauseReason: ProductPauseReason.RESERVED })).toBe(false);
    expect(canDeleteProduct({ pauseReason: ProductPauseReason.RESERVED })).toBe(false);
    expect(canEditProduct({ pauseReason: ProductPauseReason.SELLER })).toBe(true);
    expect(canDeleteProduct({ pauseReason: null })).toBe(true);
  });

  it('resumes a seller pause and its legacy no-reason form, never moderation or a reservation', () => {
    const base = { status: ProductStatus.PAUSED, deletedAt: null };
    expect(canResumeProduct({ ...base, pauseReason: ProductPauseReason.SELLER })).toBe(true);
    expect(canResumeProduct({ ...base, pauseReason: null })).toBe(true);
    expect(canResumeProduct({ ...base, pauseReason: ProductPauseReason.RESERVED })).toBe(false);
    expect(canResumeProduct({ ...base, pauseReason: ProductPauseReason.MODERATION })).toBe(false);
    expect(canResumeProduct({ status: ProductStatus.ACTIVE, pauseReason: null, deletedAt: null })).toBe(false);
    expect(canResumeProduct({ ...base, pauseReason: ProductPauseReason.SELLER, deletedAt: new Date() })).toBe(false);
  });

  it('refuses a quantity below what was already sold', () => {
    expect(canSetQuantity(3, 3)).toBe(true);
    expect(canSetQuantity(2, 3)).toBe(false);
  });
});
