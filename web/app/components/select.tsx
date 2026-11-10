import type {
  InputHTMLAttributes,
  ReactNode,
  Ref,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
} from 'react';
import { usePreHydrationValue } from './use-pre-hydration-value';

export function Select({
  label,
  error,
  children,
  id,
  ...props
}: SelectHTMLAttributes<HTMLSelectElement> & {
  label: string;
  error?: string;
  children: ReactNode;
}) {
  const selectId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`;
  return (
    <label className="grid min-w-0 grid-cols-1 gap-1.5 text-xs" htmlFor={selectId}>
      <span>{label}</span>
      <select
        {...props}
        className="min-h-[42px] min-w-0 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink"
        id={selectId}
        aria-invalid={Boolean(error)}
      >
        {children}
      </select>
      {error ? (
        <small role="alert" className="text-danger">
          {error}
        </small>
      ) : null}
    </label>
  );
}
export function TextArea({
  label,
  error,
  id,
  onChange,
  value,
  autoGrow = false,
  ...props
}: TextareaHTMLAttributes<HTMLTextAreaElement> & {
  label: string;
  error?: string;
  autoGrow?: boolean;
}) {
  const fieldId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`;
  const [ref, hydrated] = usePreHydrationValue<HTMLTextAreaElement>(onChange, value);
  const resize = (field: HTMLTextAreaElement) => {
    if (!autoGrow) return;
    field.style.height = 'auto';
    field.style.height = `${Math.min(field.scrollHeight, 200)}px`;
  };
  return (
    <label className="grid min-w-0 grid-cols-1 gap-1.5 text-xs" htmlFor={fieldId}>
      <span>{label}</span>
      <textarea
        {...props}
        className={`min-h-[42px] min-w-0 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink ${autoGrow ? 'max-h-[200px] resize-none overflow-y-auto' : ''}`}
        data-auto-grow={autoGrow ? '' : undefined}
        ref={(node) => {
          ref(node);
          if (node) resize(node);
        }}
        {...(hydrated ? { value } : { defaultValue: value })}
        onChange={(event) => {
          resize(event.currentTarget);
          onChange?.(event);
        }}
        id={fieldId}
        aria-invalid={Boolean(error)}
      />
      {error ? (
        <small role="alert" className="text-danger">
          {error}
        </small>
      ) : null}
    </label>
  );
}
export function Checkbox({
  label,
  ...props
}: InputHTMLAttributes<HTMLInputElement> & { label: string; ref?: Ref<HTMLInputElement> }) {
  return (
    <label className="flex items-start gap-2.5">
      <input {...props} className="mt-0.5 flex-none" type="checkbox" />
      <span>{label}</span>
    </label>
  );
}
