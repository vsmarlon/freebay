import { z } from 'zod';
import { orderStatuses, type EscrowStatus, type OrderStatus } from './types';

const orderStatus = z.custom<OrderStatus>(
  (value) => typeof value === 'string' && orderStatuses.includes(value as OrderStatus),
);
const escrowStatus = z.custom<EscrowStatus>((value) =>
  ['HELD', 'RELEASED', 'REFUNDED'].includes(value as string),
);

// Money is integer cents on the wire; these schemas reject anything else before
// the UI formats it. Unknown extra fields pass through so the backend can add
// fields without breaking the client.
const cents = z.number().int().nonnegative();

export const orderSchema = z
  .object({
    id: z.string(),
    buyerId: z.string(),
    sellerId: z.string(),
    productId: z.string(),
    product: z
      .object({ title: z.string(), images: z.array(z.object({ url: z.string() })).optional() })
      .passthrough()
      .optional(),
    buyer: z
      .object({
        id: z.string(),
        displayName: z.string(),
        avatarUrl: z.string().nullable().optional(),
      })
      .passthrough()
      .optional(),
    seller: z
      .object({
        id: z.string(),
        displayName: z.string(),
        avatarUrl: z.string().nullable().optional(),
      })
      .passthrough()
      .optional(),
    transaction: z
      .object({
        status: z.string().optional(),
        paymentGroupId: z.string().nullable(),
        chargeId: z.string().nullable().optional(),
        externalId: z.string().nullable().optional(),
      })
      .passthrough()
      .nullable()
      .optional(),
    dispute: z.object({ id: z.string(), status: z.string() }).passthrough().nullable().optional(),
    amount: cents,
    platformFee: cents,
    sellerAmount: cents,
    status: orderStatus,
    escrowStatus,
    createdAt: z.string(),
  })
  .passthrough();

export const checkoutGroupSchema = z
  .object({
    paymentGroupId: z.string(),
    items: z.array(
      z
        .object({
          orderId: z.string(),
          productId: z.string(),
          productTitle: z.string(),
          quantity: z.number().int().positive(),
          amount: cents,
        })
        .passthrough(),
    ),
    totalOrders: z.number().int().nonnegative(),
    totalAmount: cents,
    checkoutUrl: z.string().nullable(),
    expiresAt: z.string().nullable(),
  })
  .passthrough();

export const checkoutRecoverySchema = z
  .object({
    status: z.enum(['CHECKING', 'PAID']),
    paymentGroupId: z.string(),
    orderIds: z.array(z.string()),
    totalAmount: cents,
    checkoutUrl: z.string().nullable(),
    paymentIntentClientSecret: z.string().nullable(),
    expiresAt: z.string().nullable(),
  })
  .passthrough();

export const walletSchema = z
  .object({ balance: cents, pendingBalance: cents, availableBalance: cents })
  .passthrough();

export const ordersPageSchema = z
  .object({
    items: z.array(orderSchema),
    hasMore: z.boolean(),
    nextCursor: z.string().nullable(),
  })
  .passthrough();

export const orderEnvelopeSchema = z.object({ order: orderSchema }).passthrough();

export const orderWithActionsSchema = z
  .object({ order: orderSchema, allowedActions: z.array(z.string()) })
  .passthrough();
