// Mirrors the persisted enums: domain files must not import @prisma/client
// (ADR 0005, B5). Values are identical, so Prisma rows are accepted.
export const PRODUCT_STATUS = {
  ACTIVE: 'ACTIVE',
  SOLD: 'SOLD',
  PAUSED: 'PAUSED',
  DELETED: 'DELETED',
} as const;

export type ProductStatus = (typeof PRODUCT_STATUS)[keyof typeof PRODUCT_STATUS];

export const PRODUCT_PAUSE_REASON = {
  SELLER: 'SELLER',
  RESERVED: 'RESERVED',
  MODERATION: 'MODERATION',
} as const;

export type ProductPauseReason = (typeof PRODUCT_PAUSE_REASON)[keyof typeof PRODUCT_PAUSE_REASON];

/**
 * `PAUSED` has exactly three meanings, and they are not interchangeable:
 * the seller paused the listing, an open order reserved the last unit, or
 * moderation removed it. The reason travels with the status so a cancel or a
 * resume can only undo the pause it owns.
 */
export function isReservationHold(product: {
  status: ProductStatus;
  pauseReason: ProductPauseReason | null;
}): boolean {
  return product.status === PRODUCT_STATUS.PAUSED
    && product.pauseReason === PRODUCT_PAUSE_REASON.RESERVED;
}

/** A reserved unit is owned by an open order: the seller may not edit or delete it. */
export function canEditProduct(product: { pauseReason: ProductPauseReason | null }): boolean {
  return product.pauseReason !== PRODUCT_PAUSE_REASON.RESERVED;
}

export function canDeleteProduct(product: { pauseReason: ProductPauseReason | null }): boolean {
  return product.pauseReason !== PRODUCT_PAUSE_REASON.RESERVED;
}

/**
 * Only a seller pause is resumable by the seller. Legacy `PAUSED` rows without
 * a reason predate the split and are treated as seller pauses. A moderation
 * removal is never resumable, and a reservation is released by its order.
 */
export function canResumeProduct(product: {
  status: ProductStatus;
  pauseReason: ProductPauseReason | null;
  deletedAt: Date | null;
}): boolean {
  if (product.deletedAt !== null) return false;
  if (product.status !== PRODUCT_STATUS.PAUSED) return false;
  return product.pauseReason === null || product.pauseReason === PRODUCT_PAUSE_REASON.SELLER;
}

export function canSetQuantity(quantity: number, soldCount: number): boolean {
  return quantity >= soldCount;
}

export function sellerPauseData(): {
  status: ProductStatus;
  pauseReason: ProductPauseReason;
} {
  return { status: PRODUCT_STATUS.PAUSED, pauseReason: PRODUCT_PAUSE_REASON.SELLER };
}

export function resumeData(): {
  status: ProductStatus;
  pauseReason: null;
} {
  return { status: PRODUCT_STATUS.ACTIVE, pauseReason: null };
}

export function reservationHoldData(): {
  status: ProductStatus;
  pauseReason: ProductPauseReason;
} {
  return { status: PRODUCT_STATUS.PAUSED, pauseReason: PRODUCT_PAUSE_REASON.RESERVED };
}

export function restoredFromReservationData(): {
  status: ProductStatus;
  pauseReason: null;
} {
  return { status: PRODUCT_STATUS.ACTIVE, pauseReason: null };
}
