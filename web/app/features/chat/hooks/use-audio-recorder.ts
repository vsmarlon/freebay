import { useCallback, useEffect, useRef, useState } from 'react';

export type RecorderFailure = 'permission' | 'recorder';

const mimeTypes = ['audio/webm', 'audio/ogg', 'audio/mp4'] as const;
const extensionByMime: Record<string, string> = { 'audio/ogg': 'ogg', 'audio/mp4': 'm4a' };
const recordingLimitMs = 60_000;

// Full MediaRecorder lifecycle for the voice composer. `start()`/`stop()` are
// imperative beats; `cancel()` drops the take. The finished take reaches
// `onReady` through the latest-ref so the caller can pass a plain inline closure.
export function useAudioRecorder(onReady: (file: File, durationMs: number) => void): {
  recording: boolean;
  elapsedSeconds: number;
  unsupported: boolean;
  failure: RecorderFailure | null;
  start: () => Promise<void>;
  stop: () => void;
  cancel: () => void;
} {
  const onReadyRef = useRef(onReady);
  const [recording, setRecording] = useState(false);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [unsupported, setUnsupported] = useState(false);
  const [failure, setFailure] = useState<RecorderFailure | null>(null);

  const streamRef = useRef<MediaStream | null>(null);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const startedAt = useRef(0);
  const cancelled = useRef(false);
  const limitTimer = useRef<number | null>(null);
  const tickTimer = useRef<number | null>(null);

  useEffect(() => {
    onReadyRef.current = onReady;
  }, [onReady]);

  const teardownTimers = () => {
    if (limitTimer.current !== null) window.clearTimeout(limitTimer.current);
    if (tickTimer.current !== null) window.clearInterval(tickTimer.current);
    limitTimer.current = null;
    tickTimer.current = null;
  };

  useEffect(
    () => () => {
      // Unmount mid-take: drop the recording and release the microphone.
      cancelled.current = true;
      teardownTimers();
      if (recorderRef.current?.state === 'recording') recorderRef.current.stop();
      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    },
    [],
  );

  const start = useCallback(async () => {
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') {
      setUnsupported(true);
      return;
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      const mimeType = mimeTypes.find((type) => MediaRecorder.isTypeSupported(type));
      if (!mimeType) {
        stream.getTracks().forEach((track) => track.stop());
        streamRef.current = null;
        setUnsupported(true);
        return;
      }
      const recorder = new MediaRecorder(stream, { mimeType });
      recorderRef.current = recorder;
      chunksRef.current = [];
      cancelled.current = false;
      recorder.ondataavailable = (event) => {
        if (event.data.size) chunksRef.current.push(event.data);
      };
      recorder.onstop = () => {
        stream.getTracks().forEach((track) => track.stop());
        streamRef.current = null;
        const tookMs = Math.min(
          recordingLimitMs,
          Math.max(1, Math.round(performance.now() - startedAt.current)),
        );
        const blob = new Blob(chunksRef.current, { type: mimeType });
        const takeDropped = cancelled.current || !blob.size;
        if (!takeDropped)
          onReadyRef.current(
            new File([blob], `voice-${Date.now()}.${extensionByMime[mimeType] ?? 'weba'}`, {
              type: mimeType,
            }),
            tookMs,
          );
        teardownTimers();
        chunksRef.current = [];
        setRecording(false);
        setElapsedSeconds(0);
      };
      startedAt.current = performance.now();
      recorder.start();
      setRecording(true);
      setElapsedSeconds(0);
      tickTimer.current = window.setInterval(
        () => setElapsedSeconds(Math.floor((performance.now() - startedAt.current) / 1000)),
        500,
      );
      limitTimer.current = window.setTimeout(() => {
        if (recorder.state === 'recording') recorder.stop();
      }, recordingLimitMs);
    } catch (cause) {
      streamRef.current?.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
      setUnsupported(true);
      setFailure(
        cause instanceof DOMException && cause.name === 'NotAllowedError'
          ? 'permission'
          : 'recorder',
      );
    }
  }, []);

  const stop = useCallback(() => {
    cancelled.current = false;
    recorderRef.current?.stop();
  }, []);

  const cancel = useCallback(() => {
    cancelled.current = true;
    recorderRef.current?.stop();
  }, []);

  return { recording, elapsedSeconds, unsupported, failure, start, stop, cancel };
}
