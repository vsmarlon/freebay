import { useCallback, useRef, useState } from 'react';
import type { ChangeEvent, ButtonHTMLAttributes, CSSProperties, InputHTMLAttributes, Ref, SelectHTMLAttributes, TextareaHTMLAttributes, HTMLAttributes, ReactNode } from 'react';
import { useI18n } from '../core/locale';

// ponytail: inline stroke icons instead of an icon package for this handful (moved from app-shell so features can reuse them)
const appIcons = {
  home: <><path d="M3 11.5 12 4l9 7.5" /><path d="M5.5 10v10h13V10" /></>,
  explore: <><circle cx="12" cy="12" r="9" /><path d="M15.5 8.5 13 13l-4.5 2.5L11 11z" /></>,
  sell: <><path d="M12 2H2v10l9.3 9.3a1 1 0 0 0 1.4 0l8.6-8.6a1 1 0 0 0 0-1.4L12 2z" /><path d="M7 7h.01" /></>,
  box: <><path d="M21 8a2 2 0 0 0-1-1.7l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.7l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /><path d="m3.3 7 8.7 5 8.7-5" /><path d="M12 22V12" /></>,
  messages: <path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />,
  profile: <><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></>,
  bell: <path d="M18 9a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4" />,
  menu: <path d="M4 6h16M4 12h16M4 18h16" />,
  close: <path d="M6 6l12 12M18 6 6 18" />,
  chevron: <path d="m6 9 6 6 6-6" />,
  system: <><rect x="3" y="4" width="18" height="13" rx="1" /><path d="M8 21h8m-4-4v4" /></>,
  light: <><circle cx="12" cy="12" r="4" /><path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4M2 12h2m16 0h2" /></>,
  dark: <path d="M21 13A9 9 0 1 1 11 3a7 7 0 0 0 10 10z" />,
  check: <path d="M4 12l5 5L20 7" />,
  pencil: <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4z" />,
  cart: <><circle cx="9" cy="20" r="1.5" /><circle cx="17" cy="20" r="1.5" /><path d="M3 3h2l2.4 11.7a1 1 0 0 0 1 .8h8.5a1 1 0 0 0 1-.8L20 7H6" /></>,
  heart: <path d="M12 21C7 16.5 3 13.2 3 9.2 3 6.4 5.2 4 8 4c1.6 0 3.1.8 4 2 1-1.2 2.4-2 4-2 2.8 0 5 2.4 5 5.2 0 4-4 7.3-9 11.8z" />,
  repeat: <><path d="M17 1l4 4-4 4" /><path d="M3 11V9a4 4 0 0 1 4-4h14" /><path d="M7 23l-4-4 4-4" /><path d="M21 13v2a4 4 0 0 1-4 4H7" /></>,
  bookmark: <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z" />,
  gear: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1 0 2.83 2 2 0 0 1-2.83 0l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-2 2 2 2 0 0 1-2-2v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83 0 2 2 0 0 1 0-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1-2-2 2 2 0 0 1 2-2h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 0-2.83 2 2 0 0 1 2.83 0l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 2-2 2 2 0 0 1 2 2v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 0 2 2 0 0 1 0 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 2 2 2 2 0 0 1-2 2h-.09a1.65 1.65 0 0 0-1.51 1z" /></>,
  sidebarToggle: <><rect x="3" y="4" width="18" height="16" rx="1" /><path d="M9.5 4v16" /><path d="m13.5 10-2 2 2 2" /></>,
  comment: <path d="M21 15a2 2 0 0 1-2 2H8l-5 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />,
  volumeOn: <><path d="M11 5 6 9H2v6h4l5 4V5z" /><path d="M15.54 8.46a5 5 0 0 1 0 7.07M19.07 4.93a10 10 0 0 1 0 14.14" /></>,
  volumeOff: <><path d="M11 5 6 9H2v6h4l5 4V5z" /><path d="m23 9-6 6M17 9l6 6" /></>,
  maximize: <><path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7" /></>,
  user: <><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 4-6 8-6s8 2 8 6" /></>,
  follow: <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="M19 8v6M22 11h-6" /></>,
  unfollow: <><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" /><circle cx="9" cy="7" r="4" /><path d="m19 8-6 6M13 8l6 6" /></>,
  signOut: <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><path d="M16 17l5-5-5-5M21 12H9" /></>,
  plus: <path d="M12 5v14M5 12h14" />,
  send: <><path d="M22 2 11 13" /><path d="M22 2 15 22 11 13 2 9 22 2z" /></>,
  attach: <path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.49" />,
  doc: <><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><path d="M14 2v6h6M16 13H8M16 17H8M10 9H8" /></>,
  camera: <><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z" /><circle cx="12" cy="13" r="4" /></>,
  mic: <><path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" /><path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8" /></>,
  pin: <><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></>,
  eye: <><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" /><circle cx="12" cy="12" r="3" /></>,
  palette: <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z" />,
  image: <><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><path d="M21 15l-5-5L5 21" /></>,
  archive: <><path d="M21 8v13H3V8" /><path d="M1 3h22v5H1z" /><path d="M10 12h4" /></>,
  trash: <><path d="M3 6h18" /><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" /><path d="M10 11v6M14 11v6" /></>,
  info: <><circle cx="12" cy="12" r="10" /><path d="M12 16v-4M12 8h.01" /></>,
  back: <><path d="M19 12H5" /><path d="m12 19-7-7 7-7" /></>,
  stop: <rect x="6" y="6" width="12" height="12" rx="1" />,
  mail: <><rect x="2" y="4" width="20" height="16" rx="2" /><path d="m2 7 10 6 10-6" /></>,
  lock: <><rect x="4" y="10" width="16" height="11" rx="2" /><path d="M8 10V7a4 4 0 0 1 8 0v3" /></>,
  at: <><circle cx="12" cy="12" r="4" /><path d="M16 8v5a3 3 0 0 0 6 0v-1a10 10 0 1 0-4 8" /></>,
  search: <><circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" /></>,
  minus: <path d="M5 12h14" />,
  viewOnce: <><rect x="3" y="3" width="18" height="18" rx="4" /><path d="M10 8h2v8M9 16h4" /></>,
  reply: <><path d="m9 17-6-5 6-5" /><path d="M3 12h11a6 6 0 0 1 6 6v1" /></>,
  eyeOff: <><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24" /><path d="m1 1 22 22" /></>,
  chevronRight: <path d="m9 6 6 6-6 6" />,
  globe: <><circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3a15 15 0 0 1 0 18M12 3a15 15 0 0 0 0 18" /></>,
  shield: <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />,
  smile: <><circle cx="12" cy="12" r="9" /><path d="M8.5 14.5a4 4 0 0 0 7 0" /><path d="M9 9.5h.01M15 9.5h.01" /></>,
  wallet: <><path d="M3 6a1 1 0 0 1 1-1h16a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z" /><path d="M15 11h5v4h-5a2 2 0 0 1 0-4z" /></>,
  play: <path d="M7 4.5v15l13-7.5z" />,
  pause: <><rect x="6" y="4" width="4" height="16" /><rect x="14" y="4" width="4" height="16" /></>,
} satisfies Record<string, ReactNode>;

export type IconName = keyof typeof appIcons;

export function Icon({ name, size = 18 }: { name: IconName; size?: number }) {
  return <svg aria-hidden="true" viewBox="0 0 24 24" width={size} height={size} fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">{appIcons[name]}</svg>;
}

// ponytail: values typed or autofilled into SSR forms before React hydration never reach state (the first re-render wipes them); mount-time adoption pulls them in. Selects keep the ceiling until a journey proves otherwise.
function usePreHydrationValue<T extends HTMLInputElement | HTMLTextAreaElement>(onChange: ((event: ChangeEvent<T>) => void) | undefined, controlled: unknown) {
  const adopted = useRef(false);
  const [hydrated, setHydrated] = useState(false);
  const ref = useCallback((field: T | null) => {
    if (!field) return;
    if (!adopted.current && onChange && field.value !== '' && field.value !== String(controlled ?? '')) {
      adopted.current = true;
      onChange({ currentTarget: field } as ChangeEvent<T>);
    }
    setHydrated(true);
  }, [onChange, controlled]);
  return [ref, hydrated] as const;
}

export type ButtonVariant = 'primary' | 'secondary' | 'ghost' | 'danger';
export type ButtonSize = 'sm' | 'md' | 'lg';
export function buttonClass(variant: ButtonVariant = 'primary', size: ButtonSize = 'md') { const look = variant === 'primary' ? 'bg-gradient-to-br from-[#660062] to-brand text-white shadow-[3px_3px_#660062]' : variant === 'secondary' ? 'border-[1.5px] border-ink bg-surface text-ink' : variant === 'danger' ? 'bg-danger text-white' : 'bg-transparent text-ink'; const height = size === 'sm' ? 'min-h-8' : size === 'lg' ? 'min-h-12' : 'min-h-10'; return `cursor-pointer border border-ink px-3.5 py-2 font-display text-[13px] font-bold ${height} ${look} active:translate-x-[3px] active:translate-y-[3px] active:shadow-none disabled:cursor-not-allowed disabled:opacity-50`; }
export function Button({ variant = 'primary', size = 'md', pending = false, disabled, type = 'button', className = '', children, ...props }: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: ButtonVariant; size?: ButtonSize; pending?: boolean }) { return <button {...props} type={type} disabled={disabled || pending} className={`${buttonClass(variant, size)} ${className}`}>{pending ? '… ' : null}{children}</button>; }
export function Input({ label, error, hint, id, icon, trailing, onChange, value, ...props }: InputHTMLAttributes<HTMLInputElement> & { label: string; error?: string; hint?: string; icon?: IconName; trailing?: ReactNode }) {
  const inputId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`;
  const [hydrationRef, hydrated] = usePreHydrationValue<HTMLInputElement>(onChange, value);
  const field = <input {...props} ref={hydrationRef} {...(hydrated ? { value } : { defaultValue: value })} onChange={onChange} id={inputId} aria-invalid={Boolean(error)} aria-describedby={error ? `${inputId}-error` : hint ? `${inputId}-hint` : undefined} />;
  return <div className="grid min-w-0 grid-cols-1 gap-1.5 text-xs"><label htmlFor={inputId}>{label}</label>{icon || trailing ? <span className="relative block">{icon ? <span className="pointer-events-none absolute top-1/2 left-2.5 grid -translate-y-1/2 place-items-center text-muted" aria-hidden="true"><Icon name={icon} size={16} /></span> : null}<span className={icon ? '[&>input]:pl-9' : ''}>{field}</span>{trailing ? <span className="absolute top-1/2 right-[3px] grid size-[34px] -translate-y-1/2 place-items-center">{trailing}</span> : null}</span> : field}{error ? <small id={`${inputId}-error`} role="alert" className="text-danger">{error}</small> : hint ? <small id={`${inputId}-hint`} className="text-muted">{hint}</small> : null}</div>;
}
export function PasswordInput({ label, ...props }: InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  const [visible, setVisible] = useState(false);
  const { t } = useI18n();
  return <Input label={label} {...props} type={visible ? 'text' : 'password'} icon="lock" trailing={<button type="button" className="grid size-[34px] cursor-pointer place-items-center border-0 bg-transparent text-muted hover:bg-surface-mid hover:text-ink" aria-label={visible ? t('common.hidePassword') : t('common.showPassword')} aria-pressed={visible} onClick={() => setVisible((current) => !current)}><Icon name={visible ? 'eyeOff' : 'eye'} size={16} /></button>} />;
}
export function Toggle({ label, description, checked, onChange, disabled }: { label: string; description?: string; checked: boolean; onChange: (checked: boolean) => void; disabled?: boolean }) {
  return <label className="relative flex min-h-[52px] cursor-pointer items-center justify-between gap-4 py-1"><span className="grid gap-0.5"><span>{label}</span>{description ? <small className="text-[11px] leading-[1.4] text-muted">{description}</small> : null}</span><input className="peer sr-only" type="checkbox" role="switch" checked={checked} disabled={disabled} onChange={(event) => onChange(event.currentTarget.checked)} /><span aria-hidden="true" className="relative h-[26px] w-[46px] shrink-0 border-[1.5px] border-ink bg-surface-high transition-colors peer-checked:border-brand peer-checked:bg-brand peer-focus-visible:outline-2 peer-focus-visible:outline-brand peer-focus-visible:outline-offset-2 peer-disabled:opacity-50 before:absolute before:top-0.5 before:left-0.5 before:size-[18px] before:bg-muted before:transition-[transform,background-color] before:content-[''] peer-checked:before:translate-x-5 peer-checked:before:bg-white" /></label>;
}
export function SegmentedControl<T extends string>({ label, value, options, onChange, disabled }: { label: string; value: T; options: readonly { value: T; label: string; icon?: IconName }[]; onChange: (value: T) => void; disabled?: boolean }) {
  const index = Math.max(0, options.findIndex((option) => option.value === value));
  const style = { '--segment-index': index, '--segment-count': options.length } as CSSProperties;
  return <div className="relative grid grid-flow-col auto-cols-fr border-[1.5px] border-ink bg-surface-high p-[3px] before:absolute before:inset-y-[3px]  before:left-[3px] before:w-[calc((100%-6px)/var(--segment-count))] before:border before:border-ink before:bg-surface before:transition-transform before:duration-180 before:ease-linear before:content-[''] before:transform-[translateX(calc(var(--segment-index)*100%))]" role="radiogroup" aria-label={label} style={style}>{options.map((option) => <button key={option.value} type="button" role="radio" aria-checked={option.value === value} disabled={disabled} onClick={() => onChange(option.value)} className="relative z-1 inline-flex min-h-[38px] cursor-pointer items-center justify-center gap-1.5 border-0 bg-transparent px-2.5 font-display text-[13px] font-semibold text-muted aria-checked:text-ink disabled:cursor-default disabled:opacity-50">{option.icon ? <Icon name={option.icon} size={16} /> : null}<span>{option.label}</span></button>)}</div>;
}
export function Select({ label, error, children, id, ...props }: SelectHTMLAttributes<HTMLSelectElement> & { label: string; error?: string; children: ReactNode }) { const selectId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`; return <label className="grid min-w-0 grid-cols-1 gap-1.5 text-xs" htmlFor={selectId}><span>{label}</span><select {...props} className="min-h-[42px] min-w-0 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink" id={selectId} aria-invalid={Boolean(error)}>{children}</select>{error ? <small role="alert" className="text-danger">{error}</small> : null}</label>; }
export function TextArea({ label, error, id, onChange, value, autoGrow = false, ...props }: TextareaHTMLAttributes<HTMLTextAreaElement> & { label: string; error?: string; autoGrow?: boolean }) {
  const fieldId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`;
  const [hydrationRef, hydrated] = usePreHydrationValue<HTMLTextAreaElement>(onChange, value);
  const resize = (field: HTMLTextAreaElement) => { if (!autoGrow) return; field.style.height = 'auto'; field.style.height = `${Math.min(field.scrollHeight, 200)}px`; };
  return <label className="grid min-w-0 grid-cols-1 gap-1.5 text-xs" htmlFor={fieldId}><span>{label}</span><textarea {...props} className={`min-h-[42px] min-w-0 border-[1.5px] border-ink bg-surface px-3 py-2.5 text-ink ${autoGrow ? 'max-h-[200px] resize-none overflow-y-auto' : ''}`} data-auto-grow={autoGrow ? '' : undefined} ref={(node) => { hydrationRef(node); if (node) resize(node); }} {...(hydrated ? { value } : { defaultValue: value })} onChange={(event) => { resize(event.currentTarget); onChange?.(event); }} id={fieldId} aria-invalid={Boolean(error)} />{error ? <small role="alert" className="text-danger">{error}</small> : null}</label>;
}
export function Checkbox({ label, ...props }: InputHTMLAttributes<HTMLInputElement> & { label: string; ref?: Ref<HTMLInputElement> }) { return <label className="flex items-start gap-2.5"><input {...props} className="mt-0.5 flex-none" type="checkbox" /><span>{label}</span></label>; }
export function Surface({ tone = 'base', className = '', ...props }: HTMLAttributes<HTMLDivElement> & { tone?: 'base' | 'mid' | 'high' }) { const bg = tone === 'base' ? 'bg-surface' : tone === 'mid' ? 'bg-surface-mid' : 'bg-surface-high'; return <div {...props} className={`border border-(--hairline) p-4 ${bg} ${className}`} />; }
export function PageHeader({ title, description, actions }: { title: string; description?: string; actions?: ReactNode }) { return <header className="flex items-center justify-between gap-5"><div><h1 className="m-0 font-display text-[34px] font-bold">{title}</h1>{description ? <p>{description}</p> : null}</div>{actions ? <div className="flex flex-none items-center gap-2">{actions}</div> : null}</header>; }
export function Status({ children, tone = 'neutral' }: { children: ReactNode; tone?: 'success' | 'warning' | 'error' | 'info' | 'neutral' }) { const color = tone === 'success' ? 'text-success' : tone === 'warning' ? 'text-warning' : tone === 'error' ? 'text-danger' : tone === 'info' ? 'text-info' : ''; return <span className={`inline-flex bg-surface-mid px-2 py-1 text-[11px] font-bold ${color}`}>{children}</span>; }
export function Loading({ label, rows = 3 }: { label?: string; rows?: number }) { const { t } = useI18n(); return <div role="status" aria-label={label ?? t('common.loading')} className="grid gap-3">{Array.from({ length: Math.max(1, rows) }, (_, i) => <span key={i} className="h-14 animate-[shimmer_1000ms_linear_infinite_alternate] bg-surface-mid" />)}</div>; }
export function Empty({ title, description, action }: { title: string; description?: string; action?: ReactNode }) { return <section className="border border-(--hairline) bg-surface p-8 text-center"><h2>{title}</h2>{description ? <p>{description}</p> : null}{action}</section>; }
export function ErrorState({ error, onRetry }: { error: unknown; onRetry?: () => void }) { const { t } = useI18n(); return <section className="grid justify-items-center gap-3.5 border border-(--hairline) bg-surface p-8 text-center" role="alert"><p>{error instanceof Error ? error.message : t('common.error')}</p>{onRetry ? <Button variant="secondary" onClick={onRetry}>{t('common.retry')}</Button> : null}</section>; }
export function Dialog({ open, onClose, title, children, actions }: { open: boolean; onClose: () => void; title: string; children: ReactNode; actions?: ReactNode }) { const sync = useCallback((dialog: HTMLDialogElement | null) => { if (!dialog) return; if (open && !dialog.open) dialog.showModal(); if (!open && dialog.open) dialog.close(); }, [open]); const { t } = useI18n(); return <dialog ref={sync} aria-label={title} aria-modal="true" onCancel={(event) => { event.preventDefault(); onClose(); }} className="absolute inset-0 m-auto max-h-[calc(100svh-32px)] w-[min(480px,calc(100vw-32px))] overflow-auto border-2 border-ink bg-surface p-6 text-ink shadow-[3px_3px_var(--edge)] backdrop:bg-[#11100e99]"><h2>{title}</h2>{children}<footer className="mx-0 mt-4 flex justify-end gap-2 border-0 p-0">{actions}<Button variant="ghost" onClick={onClose}>{t('common.close')}</Button></footer></dialog>; }
export function Avatar({ src, name, size = 40 }: { src?: string | null; name: string; size?: number }) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null);
  if (src && failedSrc !== src) return <img className="border border-ink bg-surface-mid object-cover" src={src} alt={name} width={size} height={size} loading="lazy" onError={() => setFailedSrc(src)} />;
  const initials = name.trim().split(/\s+/).slice(0, 2).map((part) => part[0]).join('').toUpperCase() || '?';
  return <span className="inline-grid flex-none place-items-center border border-ink bg-surface-mid font-display font-bold leading-none text-ink" role="img" aria-label={name} style={{ width: size, height: size, fontSize: Math.round(size * 0.36) }}>{initials}</span>;
}
export function IconButton({ 'aria-label': label, type = 'button', className = '', ...props }: ButtonHTMLAttributes<HTMLButtonElement> & { 'aria-label': string }) { return <button {...props} type={type} aria-label={label} className={`grid size-[38px] cursor-pointer place-items-center border border-ink bg-surface-mid p-0 text-ink aria-pressed:opacity-60 disabled:cursor-not-allowed disabled:opacity-50 max-[760px]:size-[34px] ${className}`} />; }
export { ComposerInput, type ComposerInputProps } from './composer-input';
export { ImageViewer, type ImageViewerItem } from './image-viewer';
export { FilePicker } from './file-picker';
export { VideoEditor } from './video-editor';
