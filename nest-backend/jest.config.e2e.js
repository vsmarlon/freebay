module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'test/e2e',
  testRegex: '.*\\.e2e-spec\\.ts$',
  maxWorkers: 1,
  transform: {
    '^.+\\.(t|j)s$': [
      'ts-jest',
      {
        tsconfig: 'tsconfig.json',
      },
    ],
  },
  collectCoverageFrom: [
    '../../src/**/*.ts',
    '!../../src/**/*.spec.ts',
    '!../../src/**/*.integration-spec.ts',
    '!../../src/**/*.e2e-spec.ts',
  ],
  coverageDirectory: '../../coverage-e2e',
  testEnvironment: 'node',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/../../src/$1',
  },
  setupFiles: ['<rootDir>/setup-e2e.ts'],
  testTimeout: 60000,
  transformIgnorePatterns: ['node_modules/(?!(uuid)/)'],
};
