import { DisputeTransitionPolicy } from './dispute-transition.policy';

describe('DisputeTransitionPolicy', () => {
  let sut: DisputeTransitionPolicy;

  beforeEach(() => {
    sut = new DisputeTransitionPolicy();
  });

  describe('canResolve', () => {
    it('returns false when dispute status is RESOLVED', () => {
      expect(sut.canResolve('RESOLVED')).toBe(false);
    });

    it('returns false when dispute status is CANCELLED', () => {
      expect(sut.canResolve('CANCELLED')).toBe(false);
    });

    it('returns true when dispute status is OPEN', () => {
      expect(sut.canResolve('OPEN')).toBe(true);
    });

    it('returns true when dispute status is AWAITING_SELLER', () => {
      expect(sut.canResolve('AWAITING_SELLER')).toBe(true);
    });

    it('returns true when dispute status is AWAITING_BUYER', () => {
      expect(sut.canResolve('AWAITING_BUYER')).toBe(true);
    });

    it('returns true when dispute status is ESCALATED', () => {
      expect(sut.canResolve('ESCALATED')).toBe(true);
    });
  });

  describe('canSubmitEvidence', () => {
    it('returns false when dispute status is RESOLVED', () => {
      expect(sut.canSubmitEvidence('RESOLVED', 'BUYER')).toBe(false);
    });

    it('returns false when dispute status is CANCELLED', () => {
      expect(sut.canSubmitEvidence('CANCELLED', 'BUYER')).toBe(false);
    });

    it('returns false when dispute status is ESCALATED because the admin queue owns it', () => {
      expect(sut.canSubmitEvidence('ESCALATED', 'BUYER')).toBe(false);
      expect(sut.canSubmitEvidence('ESCALATED', 'SELLER')).toBe(false);
    });

    it('returns true for either party when dispute status is OPEN', () => {
      expect(sut.canSubmitEvidence('OPEN', 'BUYER')).toBe(true);
      expect(sut.canSubmitEvidence('OPEN', 'SELLER')).toBe(true);
    });

    it('returns true only for the seller when the dispute awaits the seller', () => {
      expect(sut.canSubmitEvidence('AWAITING_SELLER', 'SELLER')).toBe(true);
      expect(sut.canSubmitEvidence('AWAITING_SELLER', 'BUYER')).toBe(false);
    });

    it('returns true only for the buyer when the dispute awaits the buyer', () => {
      expect(sut.canSubmitEvidence('AWAITING_BUYER', 'BUYER')).toBe(true);
      expect(sut.canSubmitEvidence('AWAITING_BUYER', 'SELLER')).toBe(false);
    });
  });

  describe('canWithdraw', () => {
    it('returns false when dispute status is RESOLVED', () => {
      expect(sut.canWithdraw('RESOLVED')).toBe(false);
    });

    it('returns false when dispute status is CANCELLED', () => {
      expect(sut.canWithdraw('CANCELLED')).toBe(false);
    });

    it('returns true when dispute status is OPEN', () => {
      expect(sut.canWithdraw('OPEN')).toBe(true);
    });

    it('returns true when dispute status is AWAITING_SELLER', () => {
      expect(sut.canWithdraw('AWAITING_SELLER')).toBe(true);
    });

    it('returns true when dispute status is AWAITING_BUYER', () => {
      expect(sut.canWithdraw('AWAITING_BUYER')).toBe(true);
    });

    it('returns true when dispute status is ESCALATED', () => {
      expect(sut.canWithdraw('ESCALATED')).toBe(true);
    });
  });

  describe('isOpener', () => {
    it('returns true when userId matches dispute.openedById', () => {
      expect(sut.isOpener({ openedById: 'buyer-1' }, 'buyer-1')).toBe(true);
    });

    it('returns false when userId does not match dispute.openedById', () => {
      expect(sut.isOpener({ openedById: 'buyer-1' }, 'seller-1')).toBe(false);
    });
  });
});
