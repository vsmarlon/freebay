import { useCallback, useRef, useState } from 'react';
import type { ChangeEvent } from 'react';

// ponytail: values typed or autofilled into SSR forms before React hydration never reach state (the first re-render wipes them); mount-time adoption pulls them in. Selects keep the ceiling until a journey proves otherwise.
export function usePreHydrationValue<T extends HTMLInputElement | HTMLTextAreaElement>(
  onChange: ((event: ChangeEvent<T>) => void) | undefined,
  controlled: unknown,
) {
  const adopted = useRef(false);
  const [hydrated, setHydrated] = useState(false);
  const ref = useCallback(
    (field: T | null) => {
      if (!field) return;
      if (
        !adopted.current &&
        onChange &&
        field.value !== '' &&
        field.value !== String(controlled ?? '')
      ) {
        adopted.current = true;
        onChange({ currentTarget: field } as ChangeEvent<T>);
      }
      setHydrated(true);
    },
    [onChange, controlled],
  );
  return [ref, hydrated] as const;
}
