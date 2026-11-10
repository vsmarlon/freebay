import { useEffect, useRef } from 'react';

/**
 * Returns a ref that always holds the latest value. Read it in event handlers,
 * async callbacks or callback refs — never during render.
 */
export function useLatest<T>(value: T) {
  const ref = useRef(value);

  // The linter forbids writing refs during render, so the sync lives here, once.
  useEffect(() => {
    ref.current = value;
  }, [value]);

  return ref;
}
