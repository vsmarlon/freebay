import type { IconName } from './icon-paths';
export type { IconName } from './icon-paths';
import { appIcons } from './icon-paths';

export function Icon({ name, size = 18 }: { name: IconName; size?: number }) {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      width={size}
      height={size}
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {appIcons[name]}
    </svg>
  );
}
