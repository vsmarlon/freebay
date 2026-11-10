import { useCallback, useState } from 'react';
import { loadImageResource, type LoadedSource } from './load-image';

/**
 * The decoded image arrives asynchronously: load it through a callback ref and
 * hold the result in state. `use()` with a promise created during render
 * suspends the shell in a loop until React gives up with "async Client
 * Component" — seen live as a full Application Error when attaching any photo
 * on web.
 */
export function useImageSource(file: File) {
  const [loaded, setLoaded] = useState<LoadedSource | null>(null);
  const [image, setImage] = useState<CanvasImageSource | null>(null);
  const [size, setSize] = useState({ width: 0, height: 0 });

  const sourceRef = useCallback(
    (node: HTMLElement | null) => {
      if (!node) return;
      let alive = true;
      void loadImageResource(file).then((result) => {
        if (!alive) return;
        setLoaded(result);
        if (!('error' in result)) {
          setImage(result.source);
          setSize({ width: result.width, height: result.height });
        }
      });
      return () => {
        alive = false;
      };
    },
    [file],
  );

  return { loaded, image, setImage, size, setSize, sourceRef };
}
