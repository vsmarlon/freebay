import type { ButtonHTMLAttributes } from 'react';
export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';
export function buttonClass(variant: ButtonVariant = 'primary', size: ButtonSize = 'md') {
  const look =
    variant === 'primary'
      ? 'bg-gradient-to-br from-[#660062] to-brand text-white shadow-[3px_3px_#660062]'
      : variant === 'secondary'
        ? 'border-[1.5px] border-ink bg-surface text-ink'
        : variant === 'danger'
          ? 'bg-danger text-white'
          : 'bg-transparent text-ink';
  const height = size === 'sm' ? 'min-h-8' : size === 'lg' ? 'min-h-12' : 'min-h-10';
  return `cursor-pointer border border-ink px-3.5 py-2 font-display text-[13px] font-bold ${height} ${look} active:translate-x-[3px] active:translate-y-[3px] active:shadow-none disabled:cursor-not-allowed disabled:opacity-50`;
}
export function Button({
  variant = 'primary',
  size = 'md',
  pending = false,
  disabled,
  type = 'button',
  className = '',
  children,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & {
  variant?: ButtonVariant;
  size?: ButtonSize;
  pending?: boolean;
}) {
  return (
    <button
      {...props}
      type={type}
      disabled={disabled || pending}
      className={`${buttonClass(variant, size)} ${className}`}
    >
      {pending ? '… ' : null}
      {children}
    </button>
  );
}
