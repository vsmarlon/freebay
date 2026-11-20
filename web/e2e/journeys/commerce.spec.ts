import { expect, test } from '@playwright/test';
import { disputeId, installBrowserFixture, openProtectedRoute, orderId } from './browser-fixture';

test('purchases list follows backend state and a PENDING payment-group order offers no actions', async ({
  page,
}) => {
  const state = await installBrowserFixture(page);
  state.orderStatus = 'PENDING';
  state.orderEscrow = 'HELD';
  await openProtectedRoute(page, state, `/en/orders`);
  await expect(page.getByRole('heading', { name: 'Purchases' })).toBeVisible();
  const row = page.locator('a', { hasText: 'Câmera analógica' });
  await expect(row).toBeVisible();
  await expect(row.getByText('Pending')).toBeVisible();
  await row.click();
  await expect(page.getByRole('heading', { name: 'Order details' })).toBeVisible();
  await expect(page.getByText(`Order reference: ${orderId}`)).toBeVisible();
  await expect(page.getByText('Status:')).toBeVisible();
  await expect(page.getByText('Pending', { exact: true })).toBeVisible();
  await expect(page.getByText('Escrow:')).toBeVisible();
  await expect(page.getByText('Held', { exact: true })).toBeVisible();
  // Backend-authoritative empty allowedActions: nothing to pay (group in flight),
  // cancel, confirm or dispute.
  await expect(page.getByRole('button', { name: 'Continue to payment' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Cancel order' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Confirm receipt' })).toHaveCount(0);
  await expect(page.getByRole('link', { name: 'Open a dispute' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Mark as shipped' })).toHaveCount(0);
});

test('confirm receipt is allowed only through the server list and releases escrow', async ({
  page,
}) => {
  const state = await installBrowserFixture(page);
  state.orderStatus = 'CONFIRMED';
  state.orderEscrow = 'HELD';
  await openProtectedRoute(page, state, `/en/orders/${orderId}`);
  // CONFIRMED + PAID + HELD from the server: buyer actions only.
  await expect(page.getByRole('button', { name: 'Confirm receipt' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Cancel order' })).toBeVisible();
  await expect(page.getByRole('link', { name: 'Open a dispute' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Mark as shipped' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Mark as delivered' })).toHaveCount(0);
  await page.getByRole('button', { name: 'Confirm receipt' }).click();
  await expect(page.getByText('Confirm receipt and release funds to the seller?')).toBeVisible();
  await page.getByRole('button', { name: 'Confirm', exact: true }).click();
  await expect(page.getByText('Completed', { exact: true })).toBeVisible({ timeout: 10_000 });
  await expect(page.getByText('Released', { exact: true })).toBeVisible();
  const confirm = state.calls.find((call) => call.path === `/orders/${orderId}/confirm`);
  expect(confirm).toMatchObject({ method: 'PATCH', hasBearer: true });
  // COMPLETED + RELEASED leaves nothing left to do.
  await expect(page.getByRole('button', { name: 'Confirm receipt' })).toHaveCount(0);
  await expect(page.getByRole('button', { name: 'Cancel order' })).toHaveCount(0);
});

test('cancel order requires a reason and a step-up token and lands on CANCELLED', async ({
  page,
}) => {
  const state = await installBrowserFixture(page);
  state.orderStatus = 'CONFIRMED';
  state.orderEscrow = 'HELD';
  await openProtectedRoute(page, state, `/en/orders/${orderId}`);
  await page.getByRole('button', { name: 'Cancel order' }).click();
  const confirm = page.getByRole('button', { name: 'Confirm', exact: true });
  await expect(confirm).toBeDisabled();
  await page.getByLabel('Reason for cancellation').fill('Synthetic cancellation reason');
  await confirm.click();
  await page.getByRole('textbox', { name: 'Password', exact: true }).fill('Synthetic-password-123');
  await page.getByRole('button', { name: 'Verify and continue' }).click();
  await expect(page.getByText('Cancelled', { exact: true })).toBeVisible({ timeout: 10_000 });
  const cancel = state.calls.find((call) => call.path === `/orders/${orderId}/cancel`);
  expect(cancel).toMatchObject({
    method: 'PATCH',
    hasBearer: true,
    hasStepUp: true,
    body: { reason: 'Synthetic cancellation reason' },
  });
  expect(
    state.calls.find(
      (call) => call.path === '/auth/web/step-up' && call.stepUpPurpose === 'cancel_order',
    ),
  ).toBeDefined();
});

test('dispute open, evidence and withdraw follow the server dispute state', async ({ page }) => {
  const state = await installBrowserFixture(page);
  state.orderStatus = 'DELIVERED';
  state.orderEscrow = 'HELD';
  await openProtectedRoute(page, state, `/en/orders/${orderId}`);
  // DELIVERED keeps escrow confirmable; cancel is no longer offered.
  await expect(page.getByRole('link', { name: 'Open a dispute' })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Cancel order' })).toHaveCount(0);
  await page.getByRole('link', { name: 'Open a dispute' }).click();
  await expect(page.getByRole('heading', { name: 'Open a dispute' })).toBeVisible();
  await page.getByLabel('Reason').fill('Item arrived damaged');
  await page.getByRole('button', { name: 'Submit dispute' }).click();
  await page.getByRole('button', { name: 'Confirm', exact: true }).click();
  await expect(page.getByRole('heading', { name: 'Dispute details' })).toBeVisible();
  await expect(page.getByText('Open', { exact: true })).toBeVisible();
  const open = state.calls.find((call) => call.path === '/disputes' && call.method === 'POST');
  expect(open).toMatchObject({
    method: 'POST',
    hasBearer: true,
    body: { orderId, reason: 'Item arrived damaged' },
  });
  await page.getByLabel('Evidence statement').fill('Photos show the cracked lens on arrival');
  await page.getByRole('button', { name: 'Submit evidence' }).click();
  await expect(page.getByText('Waiting for seller')).toBeVisible({ timeout: 10_000 });
  const evidence = state.calls.find((call) => call.path === `/disputes/${disputeId}/evidence`);
  expect(evidence).toMatchObject({ method: 'POST', hasBearer: true });
  await page.getByRole('button', { name: 'Withdraw dispute' }).click();
  await page.getByRole('button', { name: 'Confirm', exact: true }).click();
  await expect(page.getByText('Cancelled', { exact: true })).toBeVisible({ timeout: 10_000 });
  const withdraw = state.calls.find((call) => call.path === `/disputes/${disputeId}/withdraw`);
  expect(withdraw).toMatchObject({ method: 'PATCH', hasBearer: true });
  // The order returns to DELIVERED with escrow still HELD.
  await page.goto(`/en/orders/${orderId}`);
  await expect(page.getByText('Delivered', { exact: true })).toBeVisible();
  await expect(page.getByText('Held', { exact: true })).toBeVisible();
});

test('admin resolves an escalated dispute in buyer favor and the order reflects the refund', async ({
  page,
}) => {
  const state = await installBrowserFixture(page);
  state.role = 'ADMIN';
  state.orderStatus = 'DISPUTED';
  state.orderEscrow = 'HELD';
  state.dispute = {
    id: disputeId,
    status: 'ESCALATED',
    reason: 'Never arrived',
    buyerEvidence: 'Tracking shows no movement',
  };
  await openProtectedRoute(page, state, `/en/admin`);
  await expect(page.getByRole('heading', { name: 'Câmera analógica' })).toBeVisible();
  await expect(page.getByText('1 dispute(s)')).toBeVisible();
  await page.getByLabel('Decision note').fill('Refund the buyer per policy');
  await page.getByRole('button', { name: 'Confirm decision' }).click();
  await expect(page.getByText('Queue empty')).toBeVisible({ timeout: 10_000 });
  const resolve = state.calls.find((call) => call.path === `/disputes/${disputeId}/resolve`);
  expect(resolve).toMatchObject({
    method: 'PATCH',
    hasBearer: true,
    body: { resolution: 'Refund the buyer per policy', winner: 'BUYER' },
  });
  await page.goto(`/en/orders/${orderId}`);
  await expect(page.getByText('Cancelled', { exact: true })).toBeVisible();
  await expect(page.getByText('Refunded', { exact: true })).toBeVisible();
  await expect(page.getByRole('button', { name: 'Confirm receipt' })).toHaveCount(0);
});

test('wallet balances, provider status and dashboard step-up follow the server', async ({
  page,
}) => {
  const state = await installBrowserFixture(page);
  await openProtectedRoute(page, state, '/en/wallet');
  await expect(page.getByRole('heading', { name: 'Wallet' })).toBeVisible();
  await expect(page.getByText('Total balance')).toBeVisible();
  await expect(page.getByText('$50.00')).toHaveCount(2);
  await expect(page.getByText('$0.00')).toHaveCount(1);
  await expect(page.getByText('Provider status: Transfer ready')).toBeVisible();
  await expect(page.getByText('Ledger')).toBeVisible();
  // transfer-ready hides onboarding; the dashboard still needs step-up.
  await expect(page.getByRole('button', { name: 'Continue onboarding' })).toHaveCount(0);
  await page.getByRole('button', { name: 'Open provider dashboard' }).click();
  await page.getByRole('textbox', { name: 'Password', exact: true }).fill('Synthetic-password-123');
  await page.getByRole('button', { name: 'Verify and continue' }).click();
  const dashboard = state.calls.find((call) => call.path === '/payments/connect/dashboard');
  await expect.poll(() => dashboard?.hasStepUp).toBe(true);
  expect(dashboard).toMatchObject({ method: 'POST', hasBearer: true });
  expect(
    state.calls.find(
      (call) => call.path === '/auth/web/step-up' && call.stepUpPurpose === 'connect_dashboard',
    ),
  ).toBeDefined();
});
