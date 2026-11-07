'use strict';

const assert = require('node:assert/strict');
const test = require('node:test');
const { summarize } = require('./summarize-jest.cjs');

test('Jest summary accepts non-empty green results without retaining test output', () => {
  assert.deepEqual(summarize({
    numTotalTestSuites: 2,
    numTotalTests: 5,
    numPassedTests: 5,
    numFailedTests: 0,
    numPendingTests: 0,
    success: true,
    testResults: [{ message: 'must not be copied' }],
  }), { suites: 2, tests: 5, passed: 5, failed: 0, skipped: 0, success: true });
});

test('Jest summary rejects empty, skipped, failed, and unsuccessful results', () => {
  const green = { numTotalTestSuites: 1, numTotalTests: 1, numPassedTests: 1, numFailedTests: 0, numPendingTests: 0, success: true };
  for (const report of [
    { ...green, numTotalTests: 0, numPassedTests: 0 },
    { ...green, numPendingTests: 1 },
    { ...green, numFailedTests: 1, success: false },
    { ...green, success: false },
  ]) assert.throws(() => summarize(report), /at least one test/);
});
