import { expect, test } from '@playwright/test';

const backendUrl = process.env.E2E_BACKEND_URL ?? 'http://127.0.0.1:43187';

test('real backend is ready and serves the public web shell', async ({ page, request }) => {
  const readiness = await request.get(`${backendUrl}/health/ready`);
  expect(readiness.ok()).toBe(true);
  await expect(readiness.json()).resolves.toMatchObject({
    status: 'ready',
    checks: { database: 'healthy', redis: 'healthy' },
  });

  await page.goto('/en');
  await expect(page).toHaveTitle(/Freebay/i);
  await expect(page.getByRole('heading', { name: /Good finds have a way of finding you/i })).toBeVisible();
});
