import { useState } from 'react';
import type { InputHTMLAttributes, ReactNode } from 'react';
import { useI18n } from '../core/locale';
import { Icon, type IconName } from './icons/icon';
import { usePreHydrationValue } from './use-pre-hydration-value';

export function Input({
  label,
  error,
  hint,
  id,
  icon,
  trailing,
  onChange,
  value,
  ...props
}: InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  error?: string;
  hint?: string;
  icon?: IconName;
  trailing?: ReactNode;
}) {
  const inputId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`;
  const [ref, hydrated] = usePreHydrationValue<HTMLInputElement>(onChange, value);
  const field = (
    <input
      {...props}
      ref={ref}
      {...(hydrated ? { value } : { defaultValue: value })}
      onChange={onChange}
      id={inputId}
      className={`min-h-[42px] w-full min-w-0 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink ${props.className ?? ''}`}
      aria-invalid={Boolean(error)}
      aria-describedby={error ? `${inputId}-error` : hint ? `${inputId}-hint` : undefined}
    />
  );
  return (
    <div className="grid min-w-0 grid-cols-1 gap-1.5 text-xs">
      <label htmlFor={inputId}>{label}</label>
      {icon || trailing ? (
        <span className="relative block">
          {icon ? (
            <span
              className="pointer-events-none absolute top-1/2 left-2.5 grid -translate-y-1/2 place-items-center text-muted"
              aria-hidden="true"
            >
              <Icon name={icon} size={16} />
            </span>
          ) : null}
          <span className={icon ? '[&>input]:pl-9' : ''}>{field}</span>
          {trailing ? (
            <span className="absolute top-1/2 right-[3px] grid size-[34px] -translate-y-1/2 place-items-center">
              {trailing}
            </span>
          ) : null}
        </span>
      ) : (
        field
      )}
      {error ? (
        <small id={`${inputId}-error`} role="alert" className="text-danger">
          {error}
        </small>
      ) : hint ? (
        <small id={`${inputId}-hint`} className="text-muted">
          {hint}
        </small>
      ) : null}
    </div>
  );
}
export function PasswordInput({
  label,
  ...props
}: InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  const [visible, setVisible] = useState(false);
  const { t } = useI18n();
  return (
    <Input
      label={label}
      {...props}
      type={visible ? 'text' : 'password'}
      icon="lock"
      trailing={
        <button
          type="button"
          className="grid size-[34px] cursor-pointer place-items-center border-0 bg-transparent text-muted hover:bg-surface-mid hover:text-ink"
          aria-label={visible ? t('common.hidePassword') : t('common.showPassword')}
          aria-pressed={visible}
          onClick={() => setVisible((current) => !current)}
        >
          <Icon name={visible ? 'eyeOff' : 'eye'} size={16} />
        </button>
      }
    />
  );
}
