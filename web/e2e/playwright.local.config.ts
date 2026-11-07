// Local-only runner: same as playwright.config.ts but on ports 5174/3333 so it never touches a dev server on 5173.
import { defineConfig, devices } from '@playwright/test';
import { tmpdir } from 'node:os';
import path from 'node:path';

process.env.E2E_BASE_URL = 'http://127.0.0.1:5174';

export default defineConfig({
  testDir: './journeys',
  outputDir: path.resolve(process.env.PLAYWRIGHT_OUTPUT_DIR ?? path.join(tmpdir(), 'freebay-playwright-local-output')),
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: 'http://127.0.0.1:5174',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: [
    {
      command: 'node fixture-backend.mjs',
      cwd: '.',
      url: 'http://127.0.0.1:3333/health',
      timeout: 60_000,
      reuseExistingServer: false,
      stdout: 'pipe',
      stderr: 'pipe',
      env: { PORT: '3333' },
    },
    {
      command: 'npm run dev -- --port 5174 --strictPort',
      cwd: '..',
      url: 'http://127.0.0.1:5174/pt-BR',
      timeout: 60_000,
      reuseExistingServer: false,
      stdout: 'pipe',
      stderr: 'pipe',
      env: { BACKEND_URL: 'http://127.0.0.1:3333' },
    },
  ],
});
