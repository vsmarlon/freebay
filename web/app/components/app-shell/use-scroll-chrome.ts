import { useCallback } from 'react';

// Mobile chrome hides on scroll down and returns on scroll up, mirroring the
// app's HideOnScrollController (12px accumulated delta, always visible at top).
// Callback ref keeps the listener tied to the header node; no effect needed.
export function useScrollChrome() {
  return useCallback((node: HTMLElement | null) => {
    if (!node) return;
    const mobile = window.matchMedia('(max-width: 639px)');
    let lastY = window.scrollY;
    let accumulated = 0;
    let hidden = false;
    const reveal = () => {
      accumulated = 0;
      if (!hidden) return;
      hidden = false;
      node.removeAttribute('data-chrome-hidden');
      node.removeAttribute('aria-hidden');
      node.inert = false;
    };
    const hide = () => {
      accumulated = 0;
      if (hidden) return;
      hidden = true;
      node.setAttribute('data-chrome-hidden', 'true');
      node.setAttribute('aria-hidden', 'true');
      node.inert = true;
    };
    const onScroll = () => {
      const y = window.scrollY;
      const delta = y - lastY;
      lastY = y;
      if (!mobile.matches || y <= 0) return reveal();
      if (delta === 0) return;
      const sameDirection = (delta > 0 && accumulated >= 0) || (delta < 0 && accumulated <= 0);
      accumulated = sameDirection ? accumulated + delta : delta;
      if (accumulated > 12) hide();
      else if (accumulated < -12) reveal();
    };
    const onViewport = () => {
      if (!mobile.matches) reveal();
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    mobile.addEventListener('change', onViewport);
    return () => {
      window.removeEventListener('scroll', onScroll);
      mobile.removeEventListener('change', onViewport);
    };
  }, []);
}
