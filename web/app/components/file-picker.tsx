import { useRef } from 'react';

// Shared single-file picker: sr-only input + styled trigger so features stop hand-rolling raw
// <input type="file"> markup. The input resets after each change so re-picking the same file works.
export function FilePicker({ label, buttonLabel, accept, capture, fileName, hint, error, id, onChange, className = '' }: {
  label: string;
  buttonLabel?: string;
  accept?: string;
  capture?: 'user' | 'environment';
  fileName?: string;
  hint?: string;
  error?: string;
  id?: string;
  onChange: (file: File | null) => void;
  className?: string;
}) {
  const inputRef = useRef<HTMLInputElement>(null);
  const fieldId = id ?? `field-${label.toLowerCase().replace(/\W+/g, '-')}`;
  return <div className={`ui-field ${className}`}>
    <label htmlFor={fieldId}>{label}</label>
    <input ref={inputRef} id={fieldId} className="sr-only" type="file" accept={accept} capture={capture} aria-describedby={error ? `${fieldId}-error` : hint ? `${fieldId}-hint` : undefined} onChange={(event) => { onChange(event.currentTarget.files?.[0] ?? null); event.currentTarget.value = ''; }} />
    <div><button type="button" className="ui-button ui-secondary" onClick={() => inputRef.current?.click()}>{buttonLabel ?? label}</button>{fileName ? <small className="ml-3 break-all">{fileName}</small> : null}</div>
    {error ? <small id={`${fieldId}-error`} role="alert">{error}</small> : hint ? <small id={`${fieldId}-hint`}>{hint}</small> : null}
  </div>;
}
