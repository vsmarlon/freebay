import { useState, type FormEvent } from 'react';

/** Pending/error plumbing for a one-shot auth form submit. */
export function useSubmit(task: () => Promise<void>) {
  const [pending, setPending] = useState(false);
  const [error, setError] = useState(false);
  const submit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setPending(true);
    setError(false);
    try {
      await task();
    } catch {
      setError(true);
    } finally {
      setPending(false);
    }
  };
  return { submit, pending, error };
}
