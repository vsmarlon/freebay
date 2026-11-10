import { defineConfig, devices } from '@playwright/test';

const webPort = process.env.E2E_WEB_PORT ?? '43188';
const backendUrl = process.env.E2E_BACKEND_URL ?? 'http://127.0.0.1:43187';

export default defineConfig({
  testDir: './real-backend',
  outputDir: process.env.E2E_OUTPUT_DIR ?? '/tmp/freebay-web-real-e2e',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list'], ['./safe-summary-reporter.ts']],
  use: {
    baseURL: `http://127.0.0.1:${webPort}`,
    trace: 'off',
    screenshot: 'off',
    video: 'off',
  },
  webServer: {
    command: 'node server.mjs',
    cwd: '..',
    url: `http://127.0.0.1:${webPort}`,
    timeout: 120_000,
    reuseExistingServer: false,
    env: { ...process.env, PORT: webPort, BACKEND_URL: backendUrl },
  },
  projects: [{ name: 'chromium-real-backend', use: { ...devices['Desktop Chrome'] } }],
});
