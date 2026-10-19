import { describe, expect, it } from 'vitest';
import { productInquiryDraftState } from './product-inquiry-draft';

describe('product inquiry navigation state', () => {
  it('carries product and counterpart context without creating a message payload', () => {
    const state = productInquiryDraftState('product-1', 'seller-1');

    expect(state).toEqual({ productInquiryDraft: { productId: 'product-1', targetUserId: 'seller-1' } });
    expect(state).not.toHaveProperty('message');
    expect(state).not.toHaveProperty('content');
  });
});
