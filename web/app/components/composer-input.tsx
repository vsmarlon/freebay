import { type KeyboardEvent, type Ref, type SyntheticEvent, type TextareaHTMLAttributes } from 'react';

export type ComposerInputProps = {
  label: string;
  placeholder?: string;
  value: string;
  disabled?: boolean;
  maxLength?: number;
  id?: string;
  /** Enter sends, Shift+Enter inserts a newline (chat-style). Set false for plain multiline fields (e.g. product description). Default true. */
  submitOnEnter?: boolean;
  /** Auto-grow up to 160px instead of manual resize. Default true. */
  autoGrow?: boolean;
  ref?: Ref<HTMLTextAreaElement>;
  /** Extra textarea attributes (e.g. combobox a11y for @mention pickers). */
  textareaProps?: TextareaHTMLAttributes<HTMLTextAreaElement>;
  /** Fires on change, click and keyup; caret is the current selection start so mention-style UIs can track the cursor. */
  onChange: (value: string, caret?: number) => void;
  /** Called on Enter (no Shift) when content is non-empty. Optional: omit for multiline-only fields (submitOnEnter false). */
  onSubmit?: () => void;
  /** Called on Enter (no Shift) before submitting. Return true to swallow the key (e.g. pick a @mention). */
  onSubmitOverride?: () => boolean;
};

export function ComposerInput({ label, placeholder, value, disabled, maxLength, id, submitOnEnter = true, autoGrow = true, ref, textareaProps, onChange, onSubmit, onSubmitOverride }: ComposerInputProps) {
  const resize = (field: HTMLTextAreaElement) => {
    if (!autoGrow) return;
    field.style.height = 'auto';
    field.style.height = `${Math.min(field.scrollHeight, 160)}px`;
  };
  const attach = (node: HTMLTextAreaElement | null) => {
    if (typeof ref === 'function') ref(node);
    else if (ref) ref.current = node;
    if (node) resize(node);
  };
  const sync = (event: SyntheticEvent<HTMLTextAreaElement>) => onChange(event.currentTarget.value, event.currentTarget.selectionStart ?? undefined);
  const onKeyDown = (event: KeyboardEvent<HTMLTextAreaElement>) => {
    if (event.key !== 'Enter' || event.shiftKey || !submitOnEnter) return;
    if (onSubmitOverride?.()) return;
    event.preventDefault();
    if (value.trim()) onSubmit?.();
  };
  return <div className="composer-field">
    <textarea
      {...textareaProps}
      ref={attach}
      id={id}
      aria-label={label}
      placeholder={placeholder}
      rows={1}
      maxLength={maxLength}
      value={value}
      disabled={disabled}
      onChange={(event) => { sync(event); resize(event.currentTarget); }}
      onKeyUp={sync}
      onClick={sync}
      onKeyDown={onKeyDown}
    />
  </div>;
}
