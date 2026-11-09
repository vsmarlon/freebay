import { useState } from 'react';
import { Icon } from './index';

// Own stroke icons; the stepper keeps the server value as truth and only publishes valid commits.
export function QuantityStepper({ label, increase, decrease, value, max, disabled, onCommit }: { label: string; increase: string; decrease: string; value: number; max: number; disabled: boolean; onCommit: (quantity: number) => void }) {
  const [draft, setDraft] = useState<string | null>(null);
  const text = draft ?? String(value);
  const commit = (quantity: number) => { setDraft(null); onCommit(quantity); };
  // ponytail: cap typed digits by the caller's max (999 in the listing editor), not a fixed 2
  const digits = new RegExp(`^\\d{0,${String(max).length}}$`);
  return <div className="flex w-fit items-center border-[1.5px] border-ink bg-surface [&_button]:grid [&_button]:size-9 [&_button]:cursor-pointer [&_button]:place-items-center [&_button]:border-0 [&_button]:bg-transparent [&_button]:text-ink [&_button:disabled]:cursor-default [&_button:disabled]:opacity-40 [&_button:not(:disabled):hover]:bg-surface-mid [&_input]:h-9 [&_input]:w-11 [&_input]:border-x-[1.5px] [&_input]:border-ink [&_input]:bg-transparent [&_input]:px-1 [&_input]:text-center [&_input]:text-ink [&_input::-webkit-inner-spin-button]:hidden [&_input::-webkit-outer-spin-button]:hidden">
    <button type="button" aria-label={decrease} disabled={disabled || value <= 1} onClick={() => commit(value - 1)}><Icon name="minus" size={14} /></button>
    <input aria-label={label} inputMode="numeric" pattern="[0-9]*" min={1} max={max} value={text} disabled={disabled} onChange={(event) => { if (digits.test(event.currentTarget.value)) setDraft(event.currentTarget.value); }} onBlur={() => { const parsed = Number(text); commit(/^\d+$/.test(text) ? Math.max(1, Math.min(parsed, max)) : value); }} onKeyDown={(event) => { if (event.key === 'Enter') event.currentTarget.blur(); }} />
    <button type="button" aria-label={increase} disabled={disabled || value >= max} onClick={() => commit(value + 1)}><Icon name="plus" size={14} /></button>
  </div>;
}
