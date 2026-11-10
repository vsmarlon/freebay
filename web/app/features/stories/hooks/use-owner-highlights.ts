import { useEffect, useState } from 'react';
import { storiesApi } from '../api';
import type { Highlight } from '../shared';

/**
 * Highlights of the archive owner, refetched whenever the archive page lands at
 * a different owner. Async writes only; the empty case derives instead of an
 * explicit reset.
 */
export function useOwnerHighlights(ownerId: string | undefined, errorMessage: string) {
  const [highlights, setHighlights] = useState<Highlight[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!ownerId) return;
    const controller = new AbortController();
    void storiesApi
      .highlightsOfUser(ownerId, controller.signal)
      .then((response) => setHighlights(response.highlights))
      .catch(() => {
        if (!controller.signal.aborted) setError(errorMessage);
      });
    return () => controller.abort();
  }, [ownerId, errorMessage]);

  return {
    highlights: ownerId ? highlights : [],
    setHighlights,
    error,
    setError,
  };
}
