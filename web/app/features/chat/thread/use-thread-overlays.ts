import { useState } from 'react';
import type { MediaKind } from '../model';

export type ThreadConfirmation = 'deleteConversation' | 'report' | 'block';

export function useThreadOverlays() {
  const [starredOpen, setStarredOpen] = useState(false);
  const [galleryKind, setGalleryKind] = useState<MediaKind | null>(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [confirmation, setConfirmation] = useState<ThreadConfirmation | null>(null);

  return {
    starredOpen,
    galleryKind,
    detailsOpen,
    confirmation,
    setGalleryKind,
    openDetails: () => setDetailsOpen(true),
    closeDetails: () => setDetailsOpen(false),
    openStarred: () => {
      setDetailsOpen(false);
      setStarredOpen(true);
    },
    closeStarred: () => setStarredOpen(false),
    openConfirmation: setConfirmation,
    closeConfirmation: () => setConfirmation(null),
    report: () => {
      setDetailsOpen(false);
      setConfirmation('report');
    },
  };
}

export type ThreadOverlays = ReturnType<typeof useThreadOverlays>;
