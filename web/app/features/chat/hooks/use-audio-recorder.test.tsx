import { act, fireEvent, render, screen } from '@testing-library/react';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { useAudioRecorder } from './use-audio-recorder';

const stops: string[] = [];
const recorders: FakeRecorder[] = [];

class FakeMediaStream {
  private readonly tracks = [
    {
      kind: 'audio',
      stop: () => {
        stops.push('track');
      },
    },
  ];
  getTracks() {
    return this.tracks;
  }
}

class FakeRecorder {
  static isTypeSupported = () => true;
  state = 'inactive';
  ondataavailable: ((event: { data: Blob }) => void) | null = null;
  onstop: (() => void) | null = null;
  constructor() {
    recorders.push(this);
  }
  start() {
    this.state = 'recording';
  }
  stop() {
    this.state = 'inactive';
    this.onstop?.();
  }
}

function Harness({ onReady }: { onReady: (file: File, durationMs: number) => void }) {
  const recorder = useAudioRecorder(onReady);
  return (
    <>
      <button type="button" onClick={() => void recorder.start()}>
        start
      </button>
      <p>{recorder.recording ? 'recording' : 'idle'}</p>
    </>
  );
}

const onReady = () => {};

describe('useAudioRecorder lifecycle', () => {
  beforeEach(() => {
    stops.length = 0;
    recorders.length = 0;
    vi.stubGlobal('MediaRecorder', FakeRecorder);
    vi.stubGlobal('MediaStream', FakeMediaStream);
    Object.defineProperty(navigator, 'mediaDevices', {
      configurable: true,
      value: { getUserMedia: vi.fn(async () => new MediaStream()) },
    });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it('opens one microphone stream when start is clicked twice', async () => {
    render(<Harness onReady={onReady} />);
    const start = screen.getByText('start');

    fireEvent.click(start);
    fireEvent.click(start);
    await act(async () => {});

    expect(navigator.mediaDevices.getUserMedia).toHaveBeenCalledTimes(1);
    expect(recorders).toHaveLength(1);
    expect(screen.getByText('recording')).toBeInTheDocument();
  });

  it('releases a stream granted after unmount instead of recording', async () => {
    let grant: (stream: MediaStream) => void = () => {};
    Object.defineProperty(navigator, 'mediaDevices', {
      configurable: true,
      value: {
        getUserMedia: vi.fn(async () => new Promise<MediaStream>((resolve) => (grant = resolve))),
      },
    });
    const { unmount } = render(<Harness onReady={onReady} />);

    fireEvent.click(screen.getByText('start'));
    unmount();
    await act(async () => grant(new MediaStream()));

    expect(recorders).toHaveLength(0);
    expect(stops).toEqual(['track']);
  });

  it('stops the microphone tracks when unmounted mid-take', async () => {
    const { unmount } = render(<Harness onReady={onReady} />);
    fireEvent.click(screen.getByText('start'));
    await act(async () => {});

    unmount();

    expect(stops).toEqual(['track']);
    expect(recorders[0].state).toBe('inactive');
  });
});
