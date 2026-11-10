import { useEffect, useState, type RefObject } from 'react';

/**
 * The fullscreen API is the only source of truth; reading `ref.current` during
 * render is forbidden, so the fullscreenchange listener owns the state.
 */
export function useFullscreenState(ref: RefObject<HTMLElement | null>) {
  const [isFullscreen, setIsFullscreen] = useState(false);

  useEffect(() => {
    const sync = () => setIsFullscreen(document.fullscreenElement === ref.current);
    sync();
    document.addEventListener('fullscreenchange', sync);
    return () => document.removeEventListener('fullscreenchange', sync);
  }, [ref]);

  return isFullscreen;
}
