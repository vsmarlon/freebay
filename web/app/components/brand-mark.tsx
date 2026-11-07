import type { SVGProps } from 'react';

// ponytail: the FreeBay mark — a price tag with the F punched out, deliberately not an "f in a square"; favicon.svg is the drawn-barc twin of this geometry.
// Non-overlapping subpaths (stem x13.5–16.5, top arm x16.5–23, mid arm x16.5–21) so evenodd punches each bar cleanly.
export function BrandMark(props: SVGProps<SVGSVGElement>) {
  return <svg viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" aria-hidden="true" {...props}>
    <path
      fillRule="evenodd"
      clipRule="evenodd"
      fill="currentColor"
      d="M4.5 2H20L30 16 20 30H4.5A2.5 2.5 0 0 1 2 27.5V4.5A2.5 2.5 0 0 1 4.5 2Z M9 13.2a2.8 2.8 0 1 0 0 5.6 2.8 2.8 0 0 0 0-5.6Z M13.5 7h3v18h-3Z M16.5 7h6.5v3h-6.5Z M16.5 15h4.5v3h-4.5Z"
    />
  </svg>;
}
