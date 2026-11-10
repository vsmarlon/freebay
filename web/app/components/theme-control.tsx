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
  const optionRefs = useRef<Array<HTMLButtonElement | null>>([]);

  const dismiss = (event: FocusEvent<HTMLDivElement>) => {
    if (
      !(event.relatedTarget instanceof Node) ||
      !event.currentTarget.contains(event.relatedTarget)
    )
      setOpen(false);
  };
  const escape = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key === 'Escape') {
      setOpen(false);
      buttonRef.current?.focus();
    }
  };
  const listKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (
      event.key !== 'ArrowDown' &&
      event.key !== 'ArrowUp' &&
      event.key !== 'Home' &&
      event.key !== 'End'
    )
      return;
    const options = optionRefs.current.filter(
      (option): option is HTMLButtonElement => option !== null,
    );
    if (options.length === 0) return;
    const active = document.activeElement;
    const index = active instanceof HTMLButtonElement ? options.indexOf(active) : -1;
    event.preventDefault();
    let next = index;
    if (event.key === 'ArrowDown') next = index < 0 ? 0 : (index + 1) % options.length;
    else if (event.key === 'ArrowUp')
      next = index < 0 ? options.length - 1 : (index - 1 + options.length) % options.length;
    else if (event.key === 'Home') next = 0;
    else next = options.length - 1;
    options[next]?.focus();
  };
  const choose = (value: Theme) => {
    setTheme(value);
    setOpen(false);
    buttonRef.current?.focus();
  };

  return (
    <div className="relative inline-flex" onBlur={dismiss} onKeyDown={escape}>
      <button
        ref={buttonRef}
        type="button"
        className="flex min-h-[38px] cursor-pointer items-center gap-0.5 border border-ink bg-surface-mid px-[6px] pl-[11px] text-ink hover:bg-surface-high max-[760px]:min-h-[34px] [&_svg:last-child]:opacity-75 [&_svg:last-child]:transition-transform [&_svg:last-child]:duration-180 aria-expanded:[&_svg:last-child]:rotate-180"
        aria-haspopup="listbox"
        aria-expanded={open}
        aria-label={t('marketing.theme')}
        onClick={() => setOpen((current) => !current)}
        onKeyDown={(event) => {
          if (event.key === 'ArrowDown' || event.key === 'ArrowUp') {
            event.preventDefault();
            setOpen(true);
          }
        }}
      >
        <Icon name={theme} size={18} />
        <Icon name="chevron" size={14} />
      </button>
      {open ? (
        <div
          className="absolute top-[calc(100%+6px)] right-0 z-6 grid min-w-44 gap-0.5 border-[1.5px] border-ink bg-surface p-2 shadow-[4px_4px_var(--edge)]"
          role="listbox"
          aria-label={t('marketing.theme')}
          onKeyDown={listKeyDown}
        >
          {order.map((value, index) => (
            <button
              key={value}
              ref={(node) => {
                optionRefs.current[index] = node;
              }}
              type="button"
              role="option"
              aria-selected={theme === value}
              className="flex w-full items-center gap-2.5 border-0 bg-transparent px-3 py-2.5 text-left font-display text-[13px] font-semibold text-ink hover:bg-surface-mid aria-selected:bg-surface-mid aria-selected:shadow-[2px_2px_var(--edge)] [&_svg:last-child]:ml-auto"
              onClick={() => choose(value)}
            >
              <Icon name={value} size={16} />
              {t(`marketing.theme.${value}`)}
              {theme === value ? <Icon name="check" size={14} /> : null}
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
