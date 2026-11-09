import { useState } from 'react';
import type { ButtonHTMLAttributes } from 'react';

export function Avatar({
  src,
  name,
  size = 40,
}: {
  src?: string | null;
  name: string;
  size?: number;
}) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  if (src && failedSrc !== src)
    return (
      <img
        className="border border-ink bg-surface-mid object-cover"
        src={src}
        alt={name}
        width={size}
        height={size}
        loading="lazy"
        onError={() => setFailedSrc(src)}
      />
    );
  const initials =
    name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((part) => part[0])
      .join('')
      .toUpperCase() || '?';
  return (
    <span
      className="inline-grid flex-none place-items-center border border-ink bg-surface-mid font-display font-bold leading-none text-ink"
      role="img"
      aria-label={name}
      style={{ width: size, height: size, fontSize: Math.round(size * 0.36) }}
    >
      {initials}
    </span>
  );
}
export function IconButton({
  'aria-label': label,
  type = 'button',
  className = '',
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { 'aria-label': string }) {
  return (
    <button
      {...props}
      type={type}
      aria-label={label}
      className={`grid size-[38px] cursor-pointer place-items-center border border-ink bg-surface-mid p-0 text-ink aria-pressed:opacity-60 disabled:cursor-not-allowed disabled:opacity-50 max-[760px]:size-[34px] ${className}`}
    />
  );
}
