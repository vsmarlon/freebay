import { Button, Dialog } from '../../../components';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import type { Transcript } from '../model';
import { ConversationDetailsDialog } from './conversation-details-dialog';
import { MediaGalleryDialog } from './media-gallery-dialog';
import { StarredMessagesDialog } from './starred-messages-dialog';
import type { ThreadActions } from './use-thread-actions';
import type { ThreadBackground } from './use-thread-background';
import type { ThreadConfirmation, ThreadOverlays } from './use-thread-overlays';

type DialogActions = Pick<
  ThreadActions,
  | 'setError'
  | 'toggleMute'
  | 'deleteConversation'
  | 'blockCounterpart'
  | 'reportCounterpart'
  | 'setTheme'
>;

export function ThreadDialogs({
  conversationId,
  page,
  presenceHidden,
  overlays,
  background,
  actions,
  onTogglePresence,
}: {
  conversationId: string;
  page: Transcript | undefined;
  presenceHidden: boolean;
  overlays: ThreadOverlays;
  background: ThreadBackground;
  actions: DialogActions & { muted: boolean };
  onTogglePresence: () => void;
}) {
  return (
    <>
      {overlays.galleryKind ? (
        <MediaGalleryDialog
          conversationId={conversationId}
          kind={overlays.galleryKind}
          onKindChange={overlays.setGalleryKind}
          onClose={() => overlays.setGalleryKind(null)}
          onError={actions.setError}
        />
      ) : null}
      {overlays.starredOpen ? (
        <StarredMessagesDialog conversationId={conversationId} onClose={overlays.closeStarred} />
      ) : null}
      {overlays.detailsOpen ? (
        <ConversationDetailsDialog
          page={page}
          muted={actions.muted}
          presenceHidden={presenceHidden}
          background={background.value}
          onClose={overlays.closeDetails}
          onToggleMute={() => void actions.toggleMute()}
          onTogglePresence={onTogglePresence}
          onOpenGallery={() => {
            overlays.closeDetails();
            overlays.setGalleryKind('IMAGE');
          }}
          onOpenStarred={overlays.openStarred}
          onBlock={() => overlays.openConfirmation('block')}
          onReport={overlays.report}
          onTheme={(theme) => void actions.setTheme(theme)}
          onBackgroundChange={background.setValue}
          onBackgroundUpload={(file) => void background.upload(file)}
          onBackgroundSave={() => void background.save()}
        />
      ) : null}
      <ConfirmationDialog
        confirmation={overlays.confirmation}
        overlays={overlays}
        actions={actions}
      />
    </>
  );
}

function ConfirmationDialog({
  confirmation,
  overlays,
  actions,
}: {
  confirmation: ThreadConfirmation | null;
  overlays: ThreadOverlays;
  actions: DialogActions;
}) {
  const { t } = useI18n(chatCatalogs);
  const meta: readonly [string, string, string, boolean] | null = confirmation
    ? confirmation === 'deleteConversation'
      ? [
          t('chat.deleteConversation'),
          t('chat.confirmDeleteConversation'),
          t('common.delete'),
          true,
        ]
      : confirmation === 'block'
        ? [t('chat.block'), t('chat.confirmBlock'), t('chat.block'), true]
        : [t('chat.report'), t('chat.confirmReport'), t('chat.report'), false]
    : null;

  function confirm() {
    const pending = confirmation;
    overlays.closeConfirmation();
    if (pending === 'deleteConversation') void actions.deleteConversation();
    else if (pending === 'block') void actions.blockCounterpart();
    else if (pending === 'report') void actions.reportCounterpart();
  }

  return (
    <Dialog
      open={confirmation !== null}
      onClose={overlays.closeConfirmation}
      title={meta?.[0] ?? t('common.confirm')}
      actions={
        meta ? (
          <>
            <Button variant="secondary" onClick={overlays.closeConfirmation}>
              {t('common.cancel')}
            </Button>
            <Button variant={meta[3] ? 'danger' : 'primary'} onClick={confirm}>
              {meta[2]}
            </Button>
          </>
        ) : undefined
      }
    >
      {meta?.[1]}
    </Dialog>
  );
}
