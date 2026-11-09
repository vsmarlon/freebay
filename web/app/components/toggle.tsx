import type { CSSProperties } from 'react';
import { Icon, type IconName } from './icons/icon';

export function Toggle({
  label,
  description,
  checked,
  onChange,
  disabled,
}: {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
  disabled?: boolean;
}) {
  return (
    <label className="relative flex min-h-[52px] cursor-pointer items-center justify-between gap-4 py-1">
      <span className="grid gap-0.5">
        <span>{label}</span>
        {description ? (
          <small className="text-[11px] leading-[1.4] text-muted">{description}</small>
        ) : null}
      </span>
      <input
        className="peer sr-only"
        type="checkbox"
        role="switch"
        checked={checked}
        disabled={disabled}
        onChange={(event) => onChange(event.currentTarget.checked)}
      />
      <span
        aria-hidden="true"
        className="relative h-[26px] w-[46px] shrink-0 border-[1.5px] border-ink bg-surface-high transition-colors peer-checked:border-brand peer-checked:bg-brand peer-focus-visible:outline-2 peer-focus-visible:outline-brand peer-focus-visible:outline-offset-2 peer-disabled:opacity-50 before:absolute before:top-0.5 before:left-0.5 before:size-[18px] before:bg-muted before:transition-[transform,background-color] before:content-[''] peer-checked:before:translate-x-5 peer-checked:before:bg-white"
      />
    </label>
  );
}
export function SegmentedControl<T extends string>({
  label,
  value,
  options,
  onChange,
  disabled,
}: {
  label: string;
  value: T;
  options: readonly { value: T; label: string; icon?: IconName }[];
  onChange: (value: T) => void;
  disabled?: boolean;
}) {
  const index = Math.max(
    0,
    options.findIndex((option) => option.value === value),
  );
  const style = { '--segment-index': index, '--segment-count': options.length } as CSSProperties;
  return (
    <div
      className="relative grid grid-flow-col auto-cols-fr border-[1.5px] border-ink bg-surface-high p-[3px] before:absolute before:inset-y-[3px]  before:left-[3px] before:w-[calc((100%-6px)/var(--segment-count))] before:border before:border-ink before:bg-surface before:transition-transform before:duration-180 before:ease-linear before:content-[''] before:transform-[translateX(calc(var(--segment-index)*100%))]"
      role="radiogroup"
      aria-label={label}
      style={style}
    >
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          role="radio"
          aria-checked={option.value === value}
          disabled={disabled}
          onClick={() => onChange(option.value)}
          className="relative z-1 inline-flex min-h-[38px] cursor-pointer items-center justify-center gap-1.5 border-0 bg-transparent px-2.5 font-display text-[13px] font-semibold text-muted aria-checked:text-ink disabled:cursor-default disabled:opacity-50"
        >
          {option.icon ? <Icon name={option.icon} size={16} /> : null}
          <span>{option.label}</span>
        </button>
      ))}
    </div>
  );
}
