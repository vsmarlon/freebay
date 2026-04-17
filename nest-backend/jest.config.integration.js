module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.integration-spec\\.ts$',
  maxWorkers: 1, // Run tests serially to avoid DB conflicts
  transform: {
    '^.+\\.(t|j)s$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
      },
    ],
  },
  collectCoverageFrom: [
    '**/*.ts',
    '!**/*.spec.ts',
    '!**/*.integration-spec.ts',
    '!**/node_modules/**',
    '!**/dist/**',
    '!**/test/**',
  ],
  coverageDirectory: '../coverage-integration',
  testEnvironment: 'node',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
  },
  setupFilesAfterEnv: ['<rootDir>/../test/setup-integration.ts'],
  testTimeout: 30000, // 30 seconds for integration tests
  transformIgnorePatterns: ['node_modules/(?!(uuid)/)'],
};
