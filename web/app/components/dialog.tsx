import { useCallback } from 'react';
import type { ReactNode } from 'react';
import { useI18n } from '../core/locale';
import { Button } from './button';

export function Dialog({
  open,
  onClose,
  title,
  children,
  actions,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  actions?: ReactNode;
}) {
  const sync = useCallback(
    (dialog: HTMLDialogElement | null) => {
      if (!dialog) return;
      if (open && !dialog.open) dialog.showModal();
      if (!open && dialog.open) dialog.close();
    },
    [open],
  );
  const { t } = useI18n();
  return (
    <dialog
      ref={sync}
      aria-label={title}
      aria-modal="true"
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      className="absolute inset-0 m-auto max-h-[calc(100svh-32px)] w-[min(480px,calc(100vw-32px))] overflow-auto border-2 border-ink bg-surface p-6 text-ink shadow-[3px_3px_var(--edge)] backdrop:bg-[#11100e99]"
    >
      <h2>{title}</h2>
      {children}
      <footer className="mx-0 mt-4 flex justify-end gap-2 border-0 p-0">
        {actions}
        <Button variant="ghost" onClick={onClose}>
          {t('common.close')}
        </Button>
      </footer>
    </dialog>
  );
}
