// Imperative autoplay-in-view for feed videos. No React state, no effects:
// a shared IntersectionObserver drives play()/pause() directly on the elements.
// React 19 ref cleanup unregisters the element on unmount.
type SaveDataNavigator = Navigator & { connection?: { saveData?: boolean } };

let observer: IntersectionObserver | null = null;

function saveDataOn(): boolean {
  return typeof navigator !== 'undefined' && (navigator as SaveDataNavigator).connection?.saveData === true;
}

function shared(): IntersectionObserver | null {
  if (typeof IntersectionObserver === 'undefined') return null;
  observer ??= new IntersectionObserver((records) => {
    for (const record of records) {
      if (!(record.target instanceof HTMLVideoElement)) continue;
      if (record.isIntersecting && !saveDataOn()) {
        // Autoplay is only allowed muted; muted is bound from preferences on the element.
        record.target.play().catch(() => { /* blocked by the browser — user taps to play */ });
      } else {
        record.target.pause();
      }
    }
  }, { threshold: 0.35 });
  return observer;
}

// Callback ref for <video>: observe on insert, unobserve on unmount (React 19 ref cleanup).
export function trackVideo(element: HTMLVideoElement | null): (() => void) | undefined {
  if (!element) return undefined;
  const instance = shared();
  if (!instance) return undefined;
  instance.observe(element);
  return () => instance.unobserve(element);
}
