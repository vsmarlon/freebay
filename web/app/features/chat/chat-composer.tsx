import type { KeyboardEvent, Ref } from 'react';

type ChatComposerProps = {
  label: string;
  placeholder?: string;
  value: string;
  disabled?: boolean;
  maxLength?: number;
  ref?: Ref<HTMLTextAreaElement>;
  onChange: (value: string) => void;
  onSend: () => void;
};

export function ChatComposer({ label, placeholder, value, disabled, maxLength, ref, onChange, onSend }: ChatComposerProps) {
  const resize = (field: HTMLTextAreaElement) => {
    field.style.height = 'auto';
    field.style.height = `${Math.min(field.scrollHeight, 160)}px`;
  };
  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key !== 'Enter' || event.shiftKey) return;
    event.preventDefault();
    if (value.trim()) onSend();
  };
  return <div className="chat-composer-field">
    <textarea
      ref={(node) => { if (typeof ref === 'function') ref(node); else if (ref) ref.current = node; if (node) resize(node); }}
      aria-label={label}
      placeholder={placeholder}
      rows={1}
      maxLength={maxLength}
      value={value}
      disabled={disabled}
      onChange={(event) => { onChange(event.currentTarget.value); resize(event.currentTarget); }}
      onKeyDown={onKeyDown}
    />
  </div>;
}
