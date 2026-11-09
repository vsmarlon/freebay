import {
  createContext,
  useContext,
  useRef,
  useState,
  type PropsWithChildren,
} from 'react';
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
  const dismiss = () => {
    if (timer.current !== null) {
      window.clearTimeout(timer.current);
      timer.current = null;
    }
    setToast(null);
  };
  const show = (next: ToastInput) => {
    if (timer.current !== null) window.clearTimeout(timer.current);
    const id = Date.now();
    setToast({ ...next, id });
    timer.current = window.setTimeout(
      () => setToast((current) => (current?.id === id ? null : current)),
      6000,
    );
  };
  const runAction = () => {
    const action = toast?.onAction;
    dismiss();
    action?.();
  };
  return (
    <ToastContext.Provider value={{ show }}>
      {children}
      {toast ? (
        <div className="fixed bottom-[max(20px,env(safe-area-inset-bottom))] left-1/2 z-40 flex w-[min(460px,calc(100vw-32px))] -translate-x-1/2 items-center gap-3.5 border border-ink bg-ink py-3 pr-3 pl-4 text-surface shadow-[4px_4px_#0006]">
          <span className="flex-1 text-[13px]" role="status" aria-live="polite">
            {toast.message}
          </span>
          {toast.actionLabel && toast.onAction ? (
            <button
              type="button"
              className="min-h-[34px] cursor-pointer border border-current bg-transparent px-3 font-display text-xs font-bold uppercase tracking-wider text-inherit"
              onClick={runAction}
            >
              {toast.actionLabel}
            </button>
          ) : null}
          <button
            type="button"
            className="grid size-[30px] cursor-pointer place-items-center border-0 bg-transparent p-0 text-inherit opacity-70"
            aria-label={t('common.close')}
            onClick={dismiss}
          >
            <Icon name="close" size={16} />
          </button>
        </div>
      ) : null}
    </ToastContext.Provider>
  );
}

export function useToast() {
  return useContext(ToastContext);
}
