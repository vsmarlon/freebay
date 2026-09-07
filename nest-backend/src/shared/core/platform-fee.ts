export const DEFAULT_PLATFORM_FEE_PERCENT = 10;

export function getPlatformFeePercent(): number {
  const raw = process.env.PLATFORM_FEE_PERCENT;
  if (!raw) return DEFAULT_PLATFORM_FEE_PERCENT;

  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed < 0 || parsed > 100) {
    return DEFAULT_PLATFORM_FEE_PERCENT;
  }
  return parsed;
}

export function splitAmount(amount: number): { platformFee: number; sellerAmount: number } {
  const platformFee = Math.round(amount * (getPlatformFeePercent() / 100));
  return { platformFee, sellerAmount: amount - platformFee };
}
