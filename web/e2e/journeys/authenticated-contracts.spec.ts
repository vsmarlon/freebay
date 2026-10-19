import { expect, test, type Page } from '@playwright/test';
import { installBrowserFixture, productId, type BrowserFixture } from './browser-fixture';

async function finishWelcome(page: Page) {
  await page.getByRole('button', { name: 'Skip' }).click();
}

async function openProtectedRoute(page: Page, state: BrowserFixture, path: string) {
  state.profile.username = 'buyer_01';
  await page.goto(path);
  await expect(page.getByRole('button', { name: 'Skip' })).toBeVisible();
  await finishWelcome(page);
  await expect(page).toHaveURL((url) => url.pathname === new URL(path, 'http://localhost').pathname);
}

test('magic-link GET is inert, explicit confirmation consumes once, and profile completes through cookie-backed session', async ({ page }) => {
  const state = await installBrowserFixture(page);
  await page.goto('/en/register');
  await page.getByLabel('Email address').fill('synthetic@example.invalid');
  await page.getByLabel(/agree to receive product updates/i).check();
  await page.getByRole('button', { name: 'Continue with email' }).click();
  await expect(page.getByText(/if this address can receive a sign-in link/i)).toBeVisible();
  expect(state.calls.find((call) => call.path === '/auth/web/magic-link/request')).toMatchObject({ method: 'POST', hasBearer: false, body: { email: 'synthetic@example.invalid', consent: true, locale: 'en' } });

  await page.goto('/en/verify-email?token=synthetic-one-time-token');
  await expect(page.getByRole('button', { name: 'Continue and sign in' })).toBeVisible();
  await expect.poll(() => page.evaluate(() => location.search)).toBe('');
  expect(state.consumeCount).toBe(0);
  await page.getByRole('button', { name: 'Continue and sign in' }).click();
  await expect(page).toHaveURL(/\/en\/complete-profile$/);
  expect(state.consumeCount).toBe(1);
  expect(state.calls.find((call) => call.path === '/auth/web/magic-link/consume')).toMatchObject({ method: 'POST', hasBearer: false, body: { token: '[redacted]' } });

  await page.getByLabel('Username').fill('buyer_01');
  await page.getByLabel('Display name').fill('Synthetic Buyer');
  await page.getByLabel('City').fill('São Paulo');
  await page.getByLabel('State').fill('SP');
  await page.getByRole('button', { name: 'Save profile' }).click();
  await expect(page.getByRole('button', { name: 'Skip' })).toBeVisible();
  await finishWelcome(page);
  await expect(page).toHaveURL(/\/en\/feed$/);
  expect(state.profile).toMatchObject({ username: 'buyer_01', city: 'São Paulo' });
  expect(state.calls.some((call) => call.path === '/auth/web/session/access-token' && call.cookiePresent)).toBe(true);
  expect(state.calls.some((call) => call.path === '/auth/complete-profile' && call.hasBearer)).toBe(true);
  await page.screenshot({ path: 'e2e/artifacts/web-browser-authenticated-profile.png', fullPage: true });
});

test('favorite and cart remain separate; cart quantity is stock bounded and checkout uses session mode/server cents', async ({ page }) => {
  const state = await installBrowserFixture(page);
  await openProtectedRoute(page, state, '/en/feed');
  await page.goto(`/en/products/${productId}`);
  await expect(page.getByRole('heading', { name: 'Câmera analógica' })).toBeVisible();
  await expect(page.getByText(/\$\s*100\.00/)).toBeVisible();
  await expect(page.getByLabel('Quantity')).toHaveAttribute('max', '3');
  const favorite = page.getByRole('button', { name: 'Save to favorites' });
  await favorite.click();
  await expect(page.getByRole('button', { name: 'Remove favorite' })).toHaveAttribute('aria-pressed', 'true');
  await page.getByLabel('Quantity').fill('1');
  await page.getByRole('button', { name: 'Add to cart' }).click();
  await expect(page.getByText('Added to cart.')).toBeVisible();
  expect(state.favorites.has(productId)).toBe(true);
  expect(state.cartQuantity).toBe(1);

  await page.goto('/en/cart');
  await expect(page.getByRole('heading', { name: 'Your cart' })).toBeVisible();
  await expect(page.getByText(/Items \(1\)/)).toBeVisible();
  await page.getByRole('link', { name: 'Continue to checkout' }).click();
  await page.getByRole('button', { name: 'Continue to secure checkout' }).click();
  await expect(page).toHaveURL('https://checkout.stripe.com/c/pay/synthetic');
  const checkout = state.calls.find((call) => call.path === '/cart/checkout');
  expect(checkout).toMatchObject({ method: 'POST', hasBearer: true, body: { mode: 'session' } });
  expect(state.checkoutAmount).toBe(12500);
  expect(state.orderStatus).toBe('PENDING');
  await page.goto('/en/payments/success?paymentGroupId=50000000-0000-4000-8000-000000000005&payment_status=success');
  await expect(page.getByRole('heading', { name: 'Confirmation pending' })).toBeVisible();
  await expect(page.getByText('Pending')).toBeVisible();
  expect(state.orderStatus).toBe('PENDING');
  expect(state.calls.filter((call) => call.path === `/favorites/${productId}`)).toHaveLength(1);
  expect(state.calls.filter((call) => call.path === `/cart/${productId}`)).toHaveLength(1);
  await page.screenshot({ path: 'e2e/artifacts/web-browser-checkout-fixture.png', fullPage: true });
});

test('unsafe returnTo values never navigate away from the Freebay origin', async ({ page }) => {
  const state = await installBrowserFixture(page);
  state.profile.username = 'buyer_01';
  await page.goto('/en/login?returnTo=https%3A%2F%2Fevil.example%2Fcollect');
  await page.getByLabel('Password').fill('Synthetic-password-123');
  await page.getByLabel('Email address').fill('synthetic@example.invalid');
  await page.getByRole('button', { name: 'Sign in' }).click();
  await expect(page).toHaveURL(/http:\/\/127\.0\.0\.1:5173\/en\/feed$/);
  expect(state.calls.some((call) => call.path.includes('evil.example'))).toBe(false);
});

test('social comment/save round-trip follows fixture state rather than optimistic mock echoes', async ({ page }) => {
  const state = await installBrowserFixture(page);
  await openProtectedRoute(page, state, '/en/feed');
  await expect(page.getByText('Public fixture post')).toBeVisible();
  await page.getByRole('button', { name: 'Save post' }).click();
  expect(state.savedPost).toBe(true);
  await page.getByRole('link', { name: 'Comments' }).click();
  await expect(page.getByRole('heading', { name: 'Comments' })).toBeVisible();
  await page.getByLabel('Write a comment…').fill('A persisted synthetic comment');
  await page.getByRole('button', { name: 'Send' }).click();
  await expect(page.getByText('A persisted synthetic comment')).toBeVisible();
  expect(state.comments).toEqual(['A persisted synthetic comment']);
  await page.reload();
  await expect(page.locator('article').filter({ hasText: 'Public fixture post' }).getByRole('button', { name: 'Remove saved post' })).toHaveAttribute('aria-pressed', 'true');
});

test('chat sends a reply, archives the thread, and never fetches view-once media before explicit open', async ({ page }) => {
  const state = await installBrowserFixture(page);
  state.profile.username = 'buyer_01';
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'mediaDevices', { configurable: true, value: undefined });
    Object.defineProperty(window, 'MediaRecorder', { configurable: true, value: undefined });
  });
  await openProtectedRoute(page, state, '/en/messages/40000000-0000-4000-8000-000000000004');
  await expect(page.getByText('Incoming synthetic note')).toBeVisible();
  await expect(page.getByRole('button', { name: 'View once' })).toBeVisible();
  expect(state.viewOnceFetches).toBe(0);
  const incoming = page.locator('article').filter({ hasText: 'Incoming synthetic note' });
  await incoming.getByRole('button', { name: 'Message 👍' }).click();
  await expect(incoming.getByRole('button', { name: 'Message 👍' })).toContainText('1');
  await page.getByRole('button', { name: 'Star message' }).first().click();
  await expect(page.getByRole('button', { name: 'Unstar message' })).toBeVisible();
  await page.getByRole('button', { name: 'Starred messages' }).click();
  await expect(page.getByRole('dialog')).toContainText('Incoming synthetic note');
  await page.getByRole('button', { name: 'Close' }).click();
  await page.getByRole('button', { name: 'Shared media' }).click();
  await expect(page.getByRole('dialog')).toBeVisible();
  expect(state.viewOnceFetches).toBe(0);
  await page.getByRole('button', { name: 'Close' }).click();
  await page.getByRole('checkbox', { name: 'Forward 30000000-0000-4000-8000-000000000003' }).check();
  await page.getByRole('button', { name: 'Choose recipients' }).click();
  await page.getByRole('checkbox', { name: 'Synthetic Forward Target' }).check();
  await page.getByRole('button', { name: 'Forward' }).last().click();
  expect(state.calls.find((call) => call.path === '/chat/messages/forward')?.body).toMatchObject({ messageIds: ['30000000-0000-4000-8000-000000000003'], targetConversationIds: ['40000000-0000-4000-8000-000000000008'] });
  await page.locator('article').filter({ hasText: 'Incoming synthetic note' }).getByRole('button', { name: 'Reply' }).click();
  await expect(page.getByText(/Reply: Incoming synthetic note/)).toBeVisible();
  const message = page.getByRole('textbox', { name: 'Message' });
  await message.fill('Synthetic reply body');
  await page.getByRole('button', { name: 'Send' }).click();
  await expect(page.getByText('Synthetic reply body')).toBeVisible();
  expect(state.calls.find((call) => call.path.endsWith('/messages') && call.method === 'POST')?.body).toMatchObject({ content: 'Synthetic reply body', type: 'TEXT', replyToId: '30000000-0000-4000-8000-000000000003' });
  await page.getByRole('button', { name: 'Archive' }).click();
  await expect(page.getByRole('button', { name: 'Unarchive' })).toBeVisible();
  expect(state.isArchived).toBe(true);
  await page.getByRole('button', { name: 'Record audio' }).click();
  await expect(page.getByText('Audio recording is unavailable in this browser', { exact: false })).toBeVisible();
  state.viewOnceFailNextMedia = true;
  await page.getByRole('button', { name: 'View once' }).click();
  await expect.poll(() => state.viewOnceFetches).toBe(1);
  await page.getByRole('button', { name: 'Try again' }).click();
  await expect.poll(() => state.viewOnceFetches).toBe(2);
  const openIndex = state.calls.findIndex((call) => call.path.endsWith('/view-once/open'));
  const fetchIndex = state.calls.findIndex((call) => call.path.startsWith('/media/'));
  expect(openIndex).toBeGreaterThanOrEqual(0);
  expect(fetchIndex).toBeGreaterThan(openIndex);
  expect(state.calls[openIndex]).toMatchObject({ method: 'POST', body: { openingKey: '[redacted]' } });
  expect(state.calls[fetchIndex].hasViewOnceOpening).toBe(true);
  expect(state.viewOnceHeaderHashes).toHaveLength(2);
  expect(state.viewOnceHeaderHashes[0]).toBe(state.viewOnceHeaderHashes[1]);
  await page.getByRole('button', { name: 'Close' }).click();
  await expect.poll(() => state.viewOnceCloses).toBe(1);
  await page.getByRole('button', { name: 'View once' }).click();
  await expect(page.getByRole('button', { name: 'Try again' })).toBeVisible();
  expect(state.viewOnceOpens).toBe(2);
  expect(state.viewOnceFetches).toBe(2);
});

test('product contact opens a product-scoped editable greeting without auto-sending and reload does not restore it', async ({ page }) => {
  const state = await installBrowserFixture(page);
  await openProtectedRoute(page, state, '/en/feed');
  await page.goto(`/en/products/${productId}`);
  await page.getByRole('button', { name: 'Contact seller' }).click();
  await expect(page.getByRole('textbox', { name: 'Message' })).toHaveValue('Hi, is this still available?');
  expect(state.productConversationStarts).toBe(1);
  expect(state.calls.find((call) => call.path === '/chat/conversations' && call.method === 'POST')?.body).toMatchObject({ targetUserId: '20000000-0000-4000-8000-000000000002', productId });
  expect(state.calls.filter((call) => call.path.endsWith('/messages') && call.method === 'POST')).toHaveLength(0);
  const thread = page.url();
  await page.reload();
  await expect(page.getByRole('textbox', { name: 'Message' })).toHaveValue('');
  expect(state.productConversationStarts).toBe(1);
  expect(state.calls.filter((call) => call.path.endsWith('/messages') && call.method === 'POST')).toHaveLength(0);
  expect(page.url()).toBe(thread);
});

test('mute is canonical per conversation; measured location sends only the confirmed browser fix', async ({ page }) => {
  const state = await installBrowserFixture(page);
  state.profile.username = 'buyer_01';
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'geolocation', { configurable: true, value: { getCurrentPosition: (success: PositionCallback) => success({ coords: { latitude: 37.4219983, longitude: -122.084, accuracy: 7.5, altitude: null, altitudeAccuracy: null, heading: null, speed: null, toJSON: () => ({}) }, timestamp: 1791547200000, toJSON: () => ({}) }) } });
  });
  await openProtectedRoute(page, state, '/en/messages/40000000-0000-4000-8000-000000000004');
  await page.getByRole('button', { name: 'Conversation details' }).click();
  await page.getByRole('button', { name: 'Mute conversation' }).click();
  await expect(page.getByRole('button', { name: 'Unmute conversation' })).toBeVisible();
  expect(state.muted).toBe(true);
  expect(state.calls.find((call) => call.path.endsWith('/theme') && call.method === 'PATCH')?.body).toEqual({ muted: true });
  await page.getByRole('button', { name: 'Close' }).click();

  await page.getByRole('button', { name: 'Share my location' }).click();
  await page.getByRole('button', { name: 'Use current location' }).click();
  await expect(page.getByLabel('Latitude (-90 to 90)')).toHaveValue('37.4219983');
  await expect(page.getByLabel('Longitude (-180 to 180)')).toHaveValue('-122.084');
  await expect(page.getByText(/Measured accuracy: 7\.5 m/)).toBeVisible();
  await page.getByRole('button', { name: 'Send chosen location' }).click();
  await expect(page.locator('article').getByRole('button', { name: 'Share my location' })).toBeVisible();
  expect(state.locationMessages).toHaveLength(1);
  expect(state.locationMessages[0]).toMatchObject({ metadata: { latitude: 37.4219983, longitude: -122.084, accuracyMeters: 7.5, capturedAt: new Date(1791547200000).toISOString() } });
});

test('denied geolocation clears the location measurement and cannot send', async ({ page }) => {
  const state = await installBrowserFixture(page);
  state.profile.username = 'buyer_01';
  await page.addInitScript(() => {
    Object.defineProperty(navigator, 'geolocation', { configurable: true, value: { getCurrentPosition: (_success: PositionCallback, failure: PositionErrorCallback) => failure({ code: 1, message: 'denied', PERMISSION_DENIED: 1, POSITION_UNAVAILABLE: 2, TIMEOUT: 3 }) } });
  });
  await openProtectedRoute(page, state, '/en/messages/40000000-0000-4000-8000-000000000004');
  await page.getByRole('button', { name: 'Share my location' }).click();
  await page.getByRole('button', { name: 'Use current location' }).click();
  await expect(page.getByRole('alert').filter({ hasText: 'Location access was denied' })).toHaveCount(1);
  await expect(page.getByRole('button', { name: 'Send chosen location' })).toBeDisabled();
  expect(state.locationMessages).toHaveLength(0);
});

test('story view is recorded only after authenticated media loads and the next story advances on its timed interval', async ({ page }) => {
  const state = await installBrowserFixture(page);
  await openProtectedRoute(page, state, '/en/stories/20000000-0000-4000-8000-000000000002');
  await expect(page.getByText('Story 1 loaded')).toBeVisible();
  await expect.poll(() => state.calls.some((call) => call.path === '/stories/story-fixture-1/view')).toBe(true);
  const loaded = state.calls.findIndex((call) => call.path === '/media/story/story-fixture-1.png');
  const viewed = state.calls.findIndex((call) => call.path === '/stories/story-fixture-1/view');
  expect(loaded).toBeGreaterThanOrEqual(0);
  expect(viewed).toBeGreaterThan(loaded);
  expect(state.viewedStories).toContain('story-fixture-1');
  await expect(page.getByText('Story 2 loaded')).toBeVisible({ timeout: 10_000 });
  await expect.poll(() => state.calls.some((call) => call.path === '/stories/story-fixture-2/view')).toBe(true);
  expect(state.viewedStories).toContain('story-fixture-2');
});

test('profile edit, privacy step-up, deletion guard, notifications and close-friends state follow server outcomes', async ({ page }) => {
  const state = await installBrowserFixture(page);
  await openProtectedRoute(page, state, '/en/profile/edit');
  await page.getByLabel('Display name').fill('Updated Synthetic Name');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await expect(page.getByRole('status')).toHaveText('Saved.');
  await expect(page).toHaveURL(/\/en\/profile\/edit$/);
  expect(state.profile.displayName).toBe('Updated Synthetic Name');
  expect(state.calls.find((call) => call.path === '/users/me' && call.method === 'PATCH')).toMatchObject({ hasBearer: true, body: { displayName: 'Updated Synthetic Name' } });
  await page.getByRole('link', { name: 'Cancel' }).click();
  await expect(page.getByRole('heading', { name: 'Updated Synthetic Name' })).toBeVisible();
  await page.reload();
  await expect(page.getByRole('heading', { name: 'Updated Synthetic Name' })).toBeVisible();

  await page.goto('/en/settings/close-friends');
  await expect(page.getByText('Synthetic Friend')).toBeVisible();
  await page.getByRole('button', { name: 'Remove' }).click();
  await expect(page.getByRole('heading', { name: 'People' })).toBeVisible();
  expect(state.closeFriendIds.size).toBe(0);

  await page.goto('/en/notifications');
  await expect(page.getByText('Synthetic notification')).toBeVisible();
  await page.getByRole('button', { name: 'Mark all as read' }).first().click();
  expect(state.notificationsRead).toBe(true);
  expect(state.calls.some((call) => call.path === '/notifications/read-all' && call.method === 'POST')).toBe(true);

  await page.goto('/en/settings/privacy');
  await page.getByRole('button', { name: 'Export selected account data' }).click();
  await page.getByLabel('Password').fill('Synthetic-password-123');
  const download = page.waitForEvent('download');
  await page.getByRole('button', { name: 'Verify and continue' }).click();
  expect((await download).suggestedFilename()).toBe('freebay-account-export.json');
  expect(state.calls.find((call) => call.path === '/users/me/export')).toMatchObject({ hasBearer: true, hasStepUp: true });
  expect(state.calls.find((call) => call.path === '/users/me/export')?.body).toBeUndefined();

  page.once('dialog', (dialog) => void dialog.accept());
  await page.getByRole('button', { name: 'Request account deletion' }).click();
  await page.getByLabel('Password').fill('Synthetic-password-123');
  await page.getByRole('button', { name: 'Verify and continue' }).click();
  await expect(page.getByRole('alert')).toBeVisible();
  expect(state.deletionStatus).toBe(409);
  expect(state.calls.some((call) => call.path === '/users/me/web' && call.method === 'DELETE')).toBe(true);
  expect(state.calls.find((call) => call.path === '/auth/web/step-up' && (call.body as { purpose?: string }).purpose === 'delete_account')).toMatchObject({ hasBearer: true, body: { purpose: 'delete_account', proof: '[redacted]' } });

  state.profile.deletionRequestedAt = '2026-10-07T09:00:00.000Z';
  await page.goto('/en/settings/privacy');
  await expect(page.getByRole('status')).toContainText('deletion');
  page.once('dialog', (dialog) => void dialog.dismiss());
  await page.getByRole('button', { name: 'Cancel pending deletion (requires fresh sign-in)' }).click();
  expect(state.profile.deletionRequestedAt).toBe('2026-10-07T09:00:00.000Z');
  page.once('dialog', (dialog) => void dialog.accept());
  await page.getByRole('button', { name: 'Cancel pending deletion (requires fresh sign-in)' }).click();
  await expect(page.getByRole('status')).toContainText('cancelled');
  expect(state.profile.deletionRequestedAt).toBeNull();
  expect(state.calls.filter((call) => call.path === '/users/me/web/deletion/cancel' && call.method === 'PATCH')).toHaveLength(1);
  await page.screenshot({ path: 'e2e/artifacts/web-browser-account-guard.png', fullPage: true });
});
