import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import type { FullConfig, FullResult, Reporter, Suite, TestCase, TestResult } from '@playwright/test/reporter';

export default class SafeSummaryReporter implements Reporter {
  private total = 0;
  private passed = 0;
  private failed = 0;
  private skipped = 0;

  onBegin(_config: FullConfig, suite: Suite) {
    this.total = suite.allTests().length;
  }

  onTestEnd(_test: TestCase, result: TestResult) {
    if (result.status === 'passed') this.passed++;
    else if (result.status === 'skipped') this.skipped++;
    else this.failed++;
  }

  onEnd(result: FullResult) {
    const summary = {
      tests: this.total,
      passed: this.passed,
      failed: this.failed,
      skipped: this.skipped,
      status: result.status,
      success: result.status === 'passed' && this.total > 0 && this.passed > 0 && this.failed === 0 && this.skipped === 0,
      command: process.env.E2E_COMMAND ?? 'Playwright command not declared',
      fixture: process.env.E2E_FIXTURE_MODE ?? 'fixture mode not declared',
    };
    const output = process.env.E2E_SUMMARY_FILE;
    if (output) {
      mkdirSync(path.dirname(output), { recursive: true });
      writeFileSync(output, `${JSON.stringify(summary)}\n`);
    }
    process.stdout.write(`E2E summary: tests=${summary.tests} status=${summary.status}\n`);
    if (!summary.success) process.exitCode = 1;
  }
}
