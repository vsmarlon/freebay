#!/usr/bin/env node
'use strict';

const { readFileSync, writeFileSync } = require('node:fs');

function summarize(report) {
  const summary = {
    suites: report.numTotalTestSuites,
    tests: report.numTotalTests,
    passed: report.numPassedTests,
    failed: report.numFailedTests,
    skipped: report.numPendingTests,
    success: report.success === true,
  };
  if (!Number.isInteger(summary.tests) || summary.tests < 1 || summary.passed < 1 ||
      summary.failed !== 0 || summary.skipped !== 0 || !summary.success) {
    throw new Error('Jest gate must run at least one test and have no failures or skipped tests');
  }
  return summary;
}

if (require.main === module) {
  try {
    const [reportPath, summaryPath, command, fixture] = process.argv.slice(2);
    if (!reportPath || !summaryPath) throw new Error('Usage: summarize-jest.cjs <jest-json-report> <safe-summary-file>');
    const result = { ...summarize(JSON.parse(readFileSync(reportPath, 'utf8'))), command, fixture };
    writeFileSync(summaryPath, `${JSON.stringify(result)}\n`);
    process.stdout.write(`Jest summary verified: suites=${result.suites} tests=${result.tests} passed=${result.passed}\n`);
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : 'Jest report invalid'}\n`);
    process.exitCode = 1;
  }
}

module.exports = { summarize };
