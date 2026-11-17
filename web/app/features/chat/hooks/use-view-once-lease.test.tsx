import { act, fireEvent, render, screen } from '@testing-library/react';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { useViewOnceLease } from './use-view-once-lease';

const repository = vi.hoisted(() => ({
  closeViewOnce: vi.fn<
    (conversationId: string, messageId: string, openingKey: string) => Promise<void>
  >(async () => {}),
}));

vi.mock('../repository', () => ({ chatRepository: repository }));

// Mirrors media.tsx: the explicit Close cancels the lease and fires the release
// itself, so a later unmount must not fire a second one.
function Viewing({ openingKey }: { openingKey: string | null }) {
  const cancelPendingClose = useViewOnceLease({
    openingKey,
    conversationId: 'conversation',
    viewOnceMessageId: 'message',
  });
  return (
    <button
      type="button"
      onClick={() => {
        cancelPendingClose();
        void repository.closeViewOnce('conversation', 'message', openingKey ?? '');
      }}
    >
      close
    </button>
  );
}

describe('useViewOnceLease', () => {
  beforeEach(() => repository.closeViewOnce.mockClear());

  it('fires exactly one close for an armed opening, even after re-renders', async () => {
    const { rerender, unmount } = render(<Viewing openingKey="k1" />);

    rerender(<Viewing openingKey="k1" />);
    rerender(<Viewing openingKey="k1" />);
    unmount();
    await act(async () => {});

    expect(repository.closeViewOnce).toHaveBeenCalledTimes(1);
    expect(repository.closeViewOnce).toHaveBeenCalledWith('conversation', 'message', 'k1');
  });

  it('fires no lease close after an explicit Close', async () => {
    const { unmount } = render(<Viewing openingKey="k1" />);

    fireEvent.click(screen.getByText('close'));
    unmount();
    await act(async () => {});

    expect(repository.closeViewOnce).toHaveBeenCalledTimes(1);
  });
});
