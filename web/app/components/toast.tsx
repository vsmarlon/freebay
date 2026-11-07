import { createContext, useCallback, useContext, useRef, useState, type PropsWithChildren } from 'react';
import { useI18n } from '../core/locale';
import { Icon } from './index';

type ToastInput = { message: string; actionLabel?: string; onAction?: () => void };
type ToastValue = { show: (toast: ToastInput) => void };
const ToastContext = createContext<ToastValue>({ show: () => {} });

export function ToastProvider({ children }: PropsWithChildren) {
  const { t } = useI18n();
  const [toast, setToast] = useState<(ToastInput & { id: number }) | null>(null);
  // ponytail: provider lives for the whole app, so the timer is not cleared on unmount.
  const timer = useRef<number | null>(null);
  const dismiss = useCallback(() => {
    if (timer.current !== null) { window.clearTimeout(timer.current); timer.current = null; }
    setToast(null);
  }, []);
  const show = useCallback((next: ToastInput) => {
    if (timer.current !== null) window.clearTimeout(timer.current);
    const id = Date.now();
    setToast({ ...next, id });
    timer.current = window.setTimeout(() => setToast((current) => current?.id === id ? null : current), 6000);
  }, []);
  const runAction = () => {
    const action = toast?.onAction;
    dismiss();
    action?.();
  };
  return (
    <ToastContext.Provider value={{ show }}>
      {children}
      {toast ? (
        <div className="ui-toast">
          <span role="status" aria-live="polite">{toast.message}</span>
          {toast.actionLabel && toast.onAction ? <button type="button" className="ui-toast-action" onClick={runAction}>{toast.actionLabel}</button> : null}
          <button type="button" className="ui-toast-close" aria-label={t('common.close')} onClick={dismiss}><Icon name="close" size={16} /></button>
        </div>
      ) : null}
    </ToastContext.Provider>
  );
}

export function useToast() { return useContext(ToastContext); }
