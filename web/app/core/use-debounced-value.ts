import { useEffect, useState } from 'react';

// Delays mirroring `value` until typing settles: timer subscription lives in the
// effect so cleanup cancels the pending update when value (or the hook) changes.
export function useDebouncedValue(value: string, delayMs = 180): string {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = window.setTimeout(() => setDebounced(value), delayMs);
    return () => window.clearTimeout(timer);
  }, [value, delayMs]);
  return debounced;
}
