export type ProductInquiryDraftState = {
  productInquiryDraft: { productId: string; targetUserId: string };
};

export function productInquiryDraftState(productId: string, targetUserId: string): ProductInquiryDraftState {
  return { productInquiryDraft: { productId, targetUserId } };
}
