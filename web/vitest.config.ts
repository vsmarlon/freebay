import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    restoreMocks: true,
    maxWorkers: 1,
    projects: [
      {
        test: {
          name: 'unit',
          environment: 'node',
          include: ['tests/**/*.test.ts', 'app/**/*.test.ts'],
        },
      },
      {
        test: {
          name: 'components',
          environment: 'jsdom',
          include: ['app/**/*.test.tsx'],
          setupFiles: ['./tests/setup-dom.ts'],
        },
      },
    ],
  },
});
