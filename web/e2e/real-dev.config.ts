import { defineConfig, devices } from '@playwright/test';

// Drives an already-running Freebay dev server (vite, proxies to the real backend).
// The local backend only trusts http://localhost:5173, so the real-dev lane reuses
// the dev server instead of booting a new origin the backend would 401.
export default defineConfig({
  testDir: './real-backend',
  outputDir: process.env.E2E_OUTPUT_DIR ?? '../.e2e-real-artifacts',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['./safe-summary-reporter.ts']],
  use: {
    baseURL: process.env.E2E_WEB_ORIGIN ?? 'http://localhost:5173',
    trace: 'off',
    screenshot: 'off',
    video: 'off',
  },
  projects: [{ name: 'chromium-real-dev', use: { ...devices['Desktop Chrome'] } }],
});
