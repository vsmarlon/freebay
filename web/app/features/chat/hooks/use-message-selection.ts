import { useState } from 'react';

/** Multi-select state for message actions (delete, star, reply, forward). */
export function useMessageSelection() {
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [selectedTargets, setSelectedTargets] = useState<string[]>([]);

  return {
    selectedIds,
    selectedTargets,
    toggle: (id: string, checked: boolean) =>
      setSelectedIds((current) =>
        checked ? [...new Set([...current, id])] : current.filter((item) => item !== id),
      ),
    setTargets: setSelectedTargets,
    clear: () => {
      setSelectedIds([]);
      setSelectedTargets([]);
    },
  };
}

export type MessageSelection = ReturnType<typeof useMessageSelection>;
