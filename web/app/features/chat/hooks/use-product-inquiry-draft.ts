import { useEffect, useRef } from 'react';
import { useLocation, useNavigate } from 'react-router';

/**
 * Consumes the `productInquiryDraft` router state exactly once, pre-fills the
 * greeting when the composer is untouched, and clears the location state.
 */
export function useProductInquiryDraft(args: {
  ready: boolean;
  productId: string | undefined;
  otherUserId: string | undefined;
  draft: string;
  draftEdited: boolean;
  greeting: string;
  onDraft: (text: string) => void;
}) {
  const { ready, productId, otherUserId, draft, draftEdited, greeting, onDraft } = args;
  const location = useLocation();
  const navigate = useNavigate();
  const consumed = useRef(false);

  useEffect(() => {
    if (!ready || consumed.current) return;
    const inquiry = (
      location.state as {
        productInquiryDraft?: { productId?: string; targetUserId?: string };
      } | null
    )?.productInquiryDraft;
    if (!inquiry) return;
    consumed.current = true;
    if (
      !draftEdited &&
      !draft &&
      inquiry.productId === productId &&
      inquiry.targetUserId === otherUserId
    )
      onDraft(greeting);
    void navigate(`${location.pathname}${location.search}${location.hash}`, {
      replace: true,
      state: null,
    });
  }, [ready, productId, otherUserId, draft, draftEdited, greeting, onDraft, location, navigate]);
}
