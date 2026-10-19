export function dispatchAuthEmailJob(job: () => Promise<void>): void {
  // ponytail: process-memory dispatch can lose email work on restart; use a durable queue when delivery reliability requires it.
  setImmediate(() => {
    void job().catch(() => undefined);
  });
}
