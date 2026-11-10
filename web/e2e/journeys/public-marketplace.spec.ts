import { expect, test } from '@playwright/test';

test('public catalog and product metadata render in PT-BR without forwarding browser credentials', async ({
  page,
  request,
}) => {
  const mutations: string[] = [];
  page.on('request', (outgoing) => {
    const path = new URL(outgoing.url()).pathname;
    if (
      ['POST', 'PATCH', 'DELETE'].includes(outgoing.method()) &&
      (path.startsWith('/favorites/') || path.startsWith('/cart/'))
    )
      mutations.push(`${outgoing.method()} ${path}`);
  });
  await request.get('http://127.0.0.1:3333/__test/ssr-observations');
  const response = await request.get('/pt-BR/explore');
  expect(response.status()).toBe(200);
  const html = await response.text();
  expect(html).toContain('Câmera analógica');
  expect(html).toContain('Fotografia');
  expect(html).not.toContain('Authorization');
  expect(html).not.toContain('Set-Cookie');

  const productResponse = await request.get('/pt-BR/products/web-fixture-camera');
  expect(productResponse.status()).toBe(200);
  const productHtml = await productResponse.text();
  expect(productHtml).toContain('<title>Câmera analógica — Freebay</title>');
  expect(productHtml).toContain('property="og:description"');
  expect(productHtml).toContain('Pessoa de teste');
  expect(productHtml).toContain('R$ 100,00');
  const observations = await request.get('http://127.0.0.1:3333/__test/ssr-observations');
  const observationEnvelope = await observations.json();
  const ssrRequests = observationEnvelope.data as Array<{
    path: string;
    hasAuthorization: boolean;
    hasCookie: boolean;
  }>;
  expect(ssrRequests).toHaveLength(3);
  expect(ssrRequests.map(({ path }) => path).sort()).toEqual([
    '/categories',
    '/products',
    '/products/web-fixture-camera',
  ]);
  expect(
    ssrRequests.every(({ hasAuthorization, hasCookie }) => !hasAuthorization && !hasCookie),
  ).toBe(true);
  await page.goto('/pt-BR/products/web-fixture-camera');
  await expect(page.getByRole('heading', { name: 'Câmera analógica' })).toBeVisible();
  await page.getByRole('button', { name: 'Salvar nos favoritos' }).click();
  await expect(page).toHaveURL(/\/pt-BR\/login$/);
  await expect(page.getByRole('button', { name: 'Entrar' })).toBeVisible();
  await page.goto('/pt-BR/products/web-fixture-camera');
  await page.getByRole('button', { name: 'Adicionar ao carrinho' }).click();
  await expect(page).toHaveURL(/\/pt-BR\/login$/);
  expect(mutations).toEqual([]);
});

test('marketing preferences support explicit light/dark themes and mobile reflow', async ({
  page,
}) => {
  await page.setViewportSize({ width: 320, height: 780 });
  await page.goto('/pt-BR');
  await expect(page.getByRole('heading', { level: 1 })).toContainText('Bons achados');
  const themeButton = page.getByRole('button', { name: 'Tema' });
  await themeButton.click();
  await page.getByRole('option', { name: 'Escuro' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
  await expect(page.locator('body')).toHaveJSProperty('scrollWidth', 320);
  await themeButton.click();
  await page.getByRole('option', { name: 'Claro' }).click();
  await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
});
