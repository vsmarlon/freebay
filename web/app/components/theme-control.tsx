import { useRef, useState } from 'react';
import type { FocusEvent, KeyboardEvent } from 'react';
import { usePreferences, type Theme } from '../core/preferences';
import { useI18n } from '../core/locale';
import { Icon } from './index';

const order: Theme[] = ['system', 'light', 'dark'];

// Custom listbox, one code path for every browser (Firefox has no appearance:base-select until behind a flag).
// ponytail: 3-option menu — roving focus + outside-blur dismiss, same pattern as the header dropdowns. No typeahead; add it if the list ever grows.
export function ThemeControl() {
  const { theme, setTheme } = usePreferences();
  const { t } = useI18n();
  const [open, setOpen] = useState(false);
  const buttonRef = useRef<HTMLButtonElement>(null);

  const dismiss = (event: FocusEvent<HTMLDivElement>) => {
    if (!(event.relatedTarget instanceof Node) || !event.currentTarget.contains(event.relatedTarget)) setOpen(false);
  };
  const escape = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') { setOpen(false); buttonRef.current?.focus(); }
  };
  const listKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== 'ArrowDown' && event.key !== 'ArrowUp' && event.key !== 'Home' && event.key !== 'End') return;
    const options = Array.from(event.currentTarget.querySelectorAll<HTMLButtonElement>('[role="option"]'));
    if (options.length === 0) return;
    const index = options.indexOf(document.activeElement as HTMLButtonElement);
    event.preventDefault();
    let next = index;
    if (event.key === 'ArrowDown') next = index < 0 ? 0 : (index + 1) % options.length;
    else if (event.key === 'ArrowUp') next = index < 0 ? options.length - 1 : (index - 1 + options.length) % options.length;
    else if (event.key === 'Home') next = 0;
    else next = options.length - 1;
    options[next]?.focus();
  };
  const choose = (value: Theme) => { setTheme(value); setOpen(false); buttonRef.current?.focus(); };

  return (
    <div className="theme-control" onBlur={dismiss} onKeyDown={escape}>
      <button
        ref={buttonRef}
        type="button"
        className="theme-control-face"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label={t('marketing.theme')}
        onClick={() => setOpen((current) => !current)}
        onKeyDown={(event) => { if (event.key === 'ArrowDown' || event.key === 'ArrowUp') { event.preventDefault(); setOpen(true); } }}
      >
        <Icon name={theme} size={18} />
        <Icon name="chevron" size={14} />
      </button>
      {open ? (
        <div className="app-drop theme-control-picker" role="listbox" aria-label={t('marketing.theme')} onKeyDown={listKeyDown}>
          {order.map((value) => (
            <button key={value} type="button" role="option" aria-selected={theme === value} className={theme === value ? 'is-active' : undefined} onClick={() => choose(value)}>
              <Icon name={value} size={16} />{t(`marketing.theme.${value}`)}{theme === value ? <Icon name="check" size={14} /> : null}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
