import { defineConfig } from 'vitest/config';
export default defineConfig({ test: { environment: 'node', include: ['tests/**/*.test.ts', 'app/features/**/*.test.ts'], restoreMocks: true, maxWorkers: 1 } });
