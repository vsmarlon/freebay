import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './journeys',
  outputDir: './artifacts/run',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  reporter: [['list']],
  use: {
    baseURL: 'http://127.0.0.1:5173',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: [
    {
      command: 'node fixture-backend.mjs',
      cwd: '.',
      url: 'http://127.0.0.1:3333/health',
      reuseExistingServer: false,
      env: { PORT: '3333' },
    },
    {
      command: 'npm run dev -- --port 5173 --strictPort',
      cwd: '..',
      url: 'http://127.0.0.1:5173/pt-BR',
      reuseExistingServer: false,
      env: { BACKEND_URL: 'http://127.0.0.1:3333' },
    },
  ],
});
