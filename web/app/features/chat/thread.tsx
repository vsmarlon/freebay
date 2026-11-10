import { useMemo, useRef, useState, type FormEvent } from 'react';
import { Link, useNavigate, useParams } from 'react-router';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { RequireAuth, useSession } from '../../core/session';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import { api } from '../../core/api';
import { useDebouncedValue } from '../../core/use-debounced-value';
import { useMediaUrl } from '../../core/media';
import { Button, ComposerInput, Dialog, Icon, Select } from '../../components/index';
import { LocationPicker } from '../../components/location-picker';
import { useToast } from '../../components/toast';
import { ImageEditor } from '../../components/image-editor';
import { chatCatalogs } from './catalogs';
import { chatRepository } from './repository';
import {
  CHAT_REACTIONS,
  CHAT_THEMES,
  canForwardSelection,
  deletedCopy,
  locationMessageMetadata,
  mediaMessagePayload,
  type ChatMessage,
  type MediaKind,
  type Conversation,
} from './model';
import { AuthenticatedMedia } from './media';
import {
  chatKeys,
  threadMessages,
  patchThreadMessage,
  patchThreadMessages,
  patchConversationRecord,
  deleteThreadMessages,
  threadPreferenceUpdate,
  updateThreadPreference,
  conversationRecordFrom,
  useThreadTranscript,
  useConversationRecord,
  useChatSidebar,
  useMediaMessages,
  useStarredMessages,
  useForwardTargets,
} from './queries';
import { useChatSocket } from './hooks/use-chat-socket';
import { useAudioRecorder } from './hooks/use-audio-recorder';
import { usePresenceHidden } from './hooks/use-presence-hidden';
import { MessageItem } from './message-item';
import { ThreadSidebar } from './thread/thread-sidebar';
import { useScrollAnchor } from './hooks/use-scroll-anchor';
import { useProductInquiryDraft } from './hooks/use-product-inquiry-draft';
import { useMessageSelection } from './hooks/use-message-selection';

const uuid = () => crypto.randomUUID();
const isMediaType = (
  type: string,
): type is Extract<ChatMessage['type'], 'IMAGE' | 'VIDEO' | 'AUDIO'> =>
  type === 'IMAGE' || type === 'VIDEO' || type === 'AUDIO';

type SendPayload = Parameters<typeof chatRepository.send>[1];

export async function startConversation(targetUserId: string, productId?: string) {
  return chatRepository.start(targetUserId, productId);
}

function Thread() {
  const { id = '', locale = 'pt-BR' } = useParams();
  const session = useSession();
  const { t, path } = useI18n(chatCatalogs);
  const { show: showToast } = useToast();
  const navigate = useNavigate();
  const client = useQueryClient();

  const transcriptQuery = useThreadTranscript(id);
  const pages = transcriptQuery.data?.pages;
  const newestPage = pages?.[0];
  const messages = useMemo(() => (pages ? threadMessages(pages) : []), [pages]);

  const recordQuery = useConversationRecord(id, newestPage?.otherUser.displayName);
  const record = useMemo(
    () => conversationRecordFrom(recordQuery.data, id),
    [recordQuery.data, id],
  );
  const sidebarQuery = useChatSidebar();
  const sidebarConversations = sidebarQuery.data?.items ?? [];

  const socket = useChatSocket(id, newestPage?.otherUserId, session.user?.id);
  const { offline, typing, online, joinError, emitDraftActivity, emitStopTyping } = socket;

  const [draft, setDraft] = useState('');
  const [reply, setReply] = useState<ChatMessage | null>(null);
  const selection = useMessageSelection();
  const { selectedIds, selectedTargets } = selection;
  const [forwardOpen, setForwardOpen] = useState(false);
  const [forwardQuery, setForwardQuery] = useState('');
  const debouncedForwardQuery = useDebouncedValue(forwardQuery, 180);
  const forwardTargetsQuery = useForwardTargets(debouncedForwardQuery, forwardOpen);
  const [starredOpen, setStarredOpen] = useState(false);
  const starredQuery = useStarredMessages(id, starredOpen);
  const [galleryKind, setGalleryKind] = useState<MediaKind | null>(null);
  const galleryQuery = useMediaMessages(id, galleryKind);
  const galleryItems = useMemo(
    () => (galleryQuery.data ? threadMessages(galleryQuery.data.pages) : []),
    [galleryQuery.data],
  );

  const [viewOnce, setViewOnce] = useState(false);
  const [backgroundOverride, setBackgroundOverride] = useState<string | null>(null);
  const [imageToEdit, setImageToEdit] = useState<File | null>(null);
  const [imageEdited, setImageEdited] = useState(false);
  const [imageCaption, setImageCaption] = useState('');
  const [videoToSend, setVideoToSend] = useState<File | null>(null);
  const [videoCaption, setVideoCaption] = useState('');
  const [videoViewOnce, setVideoViewOnce] = useState(false);
  const [locationOpen, setLocationOpen] = useState(false);
  const [locationLatitude, setLocationLatitude] = useState('');
  const [locationLongitude, setLocationLongitude] = useState('');
  const [locationAddress, setLocationAddress] = useState('');
  const [locationAccuracy, setLocationAccuracy] = useState<number | undefined>();
  const [locationCapturedAt, setLocationCapturedAt] = useState<string | undefined>();
  const [locationError, setLocationError] = useState('');
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [confirm, setConfirm] = useState<{
    kind: 'deleteConversation' | 'deleteMessage' | 'deleteSelected' | 'report' | 'block';
    messageId?: string;
  } | null>(null);
  const [productsOpen, setProductsOpen] = useState(false);
  const [products, setProducts] = useState<
    Array<{ id: string; title: string; price: number; imageUrl: string | null }>
  >([]);
  const [productQuery, setProductQuery] = useState('');
  const [actionError, setActionError] = useState('');

  const { hidden: presenceHidden, toggle: togglePresenceHidden } = usePresenceHidden(
    session.user?.id,
    id,
  );
  const recorder = useAudioRecorder((file, durationMs) => void upload(file, durationMs));
  const recording = recorder.recording;

  const { scrollNodeRef, capture: captureScroll } = useScrollAnchor(messages.length);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const draftEdited = useRef(false);

  const send = useMutation({
    mutationFn: (payload: SendPayload) => chatRepository.send(id, payload),
    // Server truth merges into the cached transcript pages; the sidebar preview
    // updates through invalidation.
    onSuccess: (saved) => {
      patchThreadMessages(client, id, [saved]);
      void client.invalidateQueries({ queryKey: chatKeys.sidebar });
      setDraft('');
      setReply(null);
      setViewOnce(false);
      emitStopTyping();
      inputRef.current?.focus();
    },
    onError: () => setActionError(t('chat.sendError')),
  });

  // Load-immediate: seed = the cached preference; the text field is the user's
  // edited value on top of it. Data URLs pass through, /media paths resolve to
  // a blob preview through the shared authenticated-media query.
  const background = backgroundOverride ?? newestPage?.preference?.backgroundUrl ?? '';
  const backgroundIsDataUrl =
    /^data:image\/(?:png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+$/.test(background) &&
    Boolean(background);
  const backgroundMedia = useMediaUrl(
    !backgroundIsDataUrl && background.startsWith('/media/background/') ? background : null,
  );
  const backgroundImage = backgroundIsDataUrl ? background : (backgroundMedia.url ?? null);

  // Local File preview adopts the same revoke-on-gc convention (['media', …] keys).
  const videoPreview = useQuery({
    queryKey: [
      'media',
      'preview',
      videoToSend?.name ?? '',
      String(videoToSend?.size ?? 0),
      String(videoToSend?.lastModified ?? 0),
    ],
    enabled: Boolean(videoToSend),
    queryFn: async () => {
      const file = videoToSend;
      if (!file) throw new Error('preview-ready');
      return URL.createObjectURL(file);
    },
    staleTime: Infinity,
    gcTime: 5 * 60 * 1000,
    retry: false,
  });
  const videoUrl = videoToSend ? (videoPreview.data ?? null) : null;

  useProductInquiryDraft({
    ready: Boolean(newestPage && record),
    productId: record?.product?.id,
    otherUserId: newestPage?.otherUserId,
    draft,
    draftEdited: draftEdited.current,
    greeting: t('chat.productInquiryGreeting'),
    onDraft: setDraft,
  });

  async function loadOlder() {
    if (!transcriptQuery.hasNextPage || send.isPending) return;
    captureScroll();
    try {
      await transcriptQuery.fetchNextPage();
    } catch {
      setActionError(t('chat.loadError'));
    }
  }

  async function upload(
    file: File,
    durationMs?: number,
    caption?: string,
    viewOnceOverride = viewOnce,
  ) {
    setActionError('');
    try {
      const { url } = await chatRepository.upload(file);
      const type: MediaKind = file.type.startsWith('image/')
        ? 'IMAGE'
        : file.type.startsWith('video/')
          ? 'VIDEO'
          : 'AUDIO';
      await send.mutateAsync({
        ...mediaMessagePayload({
          type,
          attachmentUrl: url,
          viewOnce: viewOnceOverride,
          durationMs,
        }),
        clientMessageId: uuid(),
        ...(caption?.trim() ? { content: caption.trim() } : {}),
        ...(reply ? { replyToId: reply.id } : {}),
      });
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  function handleDraftChange(value: string) {
    draftEdited.current = true;
    setDraft(value);
    emitDraftActivity(value);
  }
  function sendDraft() {
    const content = draft.trim();
    if (!content || send.isPending) return;
    setActionError('');
    send.mutate({
      content,
      type: 'TEXT',
      clientMessageId: uuid(),
      ...(reply ? { replyToId: reply.id } : {}),
    });
  }
  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    sendDraft();
  }

  async function toggleMute() {
    const next = !muted;
    try {
      await chatRepository.mute(id, next);
      updateThreadPreference(client, id, threadPreferenceUpdate({ muted: next }));
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function uploadBackground(file: File) {
    if (!file.type.startsWith('image/')) return;
    try {
      const { url } = await chatRepository.upload(file, 'background');
      await chatRepository.background(id, url);
      setBackgroundOverride(url);
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function saveBackground() {
    if (
      background.startsWith('/media/background/') ||
      /^data:image\/(?:png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+$/.test(background)
    ) {
      try {
        await chatRepository.background(id, background);
      } catch {
        setActionError(t('chat.sendError'));
      }
    } else setActionError(t('chat.mediaError'));
  }
  async function loadOlderGallery() {
    try {
      await galleryQuery.fetchNextPage();
    } catch {
      setActionError(t('chat.loadError'));
    }
  }
  async function toggleReaction(message: ChatMessage, emoji: string) {
    try {
      const result = await chatRepository.react(id, message.id, emoji);
      patchThreadMessage(client, id, message.id, (item) => ({
        ...item,
        reactions: result.reactions,
      }));
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  function pickEmoji(emoji: string) {
    const selected = messages.filter(
      (message) => selectedIds.includes(message.id) && !message.deletedAt,
    );
    if (selected.length === 1) {
      void toggleReaction(selected[0], emoji);
      return;
    }
    const field = inputRef.current;
    if (field) {
      field.setRangeText(emoji, field.selectionStart, field.selectionEnd, 'end');
      handleDraftChange(field.value);
    }
  }
  async function copySelected() {
    const content = messages
      .filter(
        (message) => selectedIds.includes(message.id) && !message.viewOnce && !message.deletedAt,
      )
      .map((message) => message.content ?? '')
      .filter(Boolean)
      .join('\n');
    if (!content) return;
    try {
      await navigator.clipboard.writeText(content);
      selection.clear();
    } catch {
      setActionError(t('chat.clipboardError'));
    }
  }
  async function shareSelected() {
    const content = messages
      .filter(
        (message) => selectedIds.includes(message.id) && !message.viewOnce && !message.deletedAt,
      )
      .map((message) => message.content ?? '')
      .filter(Boolean)
      .join('\n');
    if (!content || !navigator.share) {
      setActionError(t('chat.shareUnsupported'));
      return;
    }
    try {
      await navigator.share({ text: content });
      selection.clear();
    } catch (cause) {
      if (!(cause instanceof DOMException && cause.name === 'AbortError'))
        setActionError(t('chat.sendError'));
    }
  }
  async function deleteSelectedMessages() {
    const deletable = messages.filter(
      (message) =>
        selectedIds.includes(message.id) &&
        message.senderId === session.user?.id &&
        !message.deletedAt,
    );
    if (!deletable.length) return;
    const settled = await Promise.allSettled(
      deletable.map((message) => chatRepository.deleteMessage(id, message.id)),
    );
    const removed = deletable
      .filter((_, index) => settled[index].status === 'fulfilled')
      .map((message) => message.id);
    if (removed.length) deleteThreadMessages(client, id, removed);
    selection.clear();
    if (settled.some((result) => result.status === 'rejected')) setActionError(t('chat.sendError'));
  }
  async function starSelected() {
    try {
      for (const messageId of selectedIds) await chatRepository.star(id, messageId);
      selection.clear();
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function openProductPicker() {
    try {
      const result = await chatRepository.myProducts();
      setProducts(result.products);
      setProductsOpen(true);
    } catch {
      setActionError(t('chat.loadError'));
    }
  }
  async function sendProductCard(product: (typeof products)[number]) {
    try {
      await send.mutateAsync({
        type: 'PRODUCT_CARD',
        clientMessageId: uuid(),
        metadata: {
          productId: product.id,
          title: product.title,
          price: product.price,
          imageUrl: product.imageUrl,
        },
      });
      setProductsOpen(false);
      setProductQuery('');
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function openExternal(url: string) {
    try {
      const parsed = new URL(url);
      if (!['https:', 'http:'].includes(parsed.protocol)) throw new Error('unsupported');
      const result = await chatRepository.verifyUrl(parsed.href);
      if (!result.isSafe || !window.confirm(t('chat.openLink') + '?\n' + result.normalizedUrl)) {
        setActionError(t('chat.unsafeLink'));
        return;
      }
      window.open(result.normalizedUrl, '_blank', 'noopener,noreferrer');
    } catch {
      setActionError(t('chat.unsafeLink'));
    }
  }
  function togglePresenceHiddenChoice() {
    const next = togglePresenceHidden();
    if (next === null) setActionError(t('chat.sendError'));
  }
  function shareLocation() {
    setLocationError('');
    setLocationOpen(true);
  }
  function sendChosenLocation() {
    // ponytail: map picks carry no measured accuracy — default to 0 m / now so the existing metadata validation still runs.
    const metadata = locationMessageMetadata({
      latitude: locationLatitude,
      longitude: locationLongitude,
      address: locationAddress,
      accuracyMeters: locationAccuracy ?? 0,
      capturedAt: locationCapturedAt ?? new Date().toISOString(),
    });
    if (!metadata) {
      setLocationError(t('chat.locationInvalid'));
      return;
    }
    setLocationError('');
    setLocationOpen(false);
    setActionError('');
    send.mutate({ type: 'LOCATION', clientMessageId: uuid(), metadata });
  }
  async function applyArchive(nextArchived: boolean) {
    await chatRepository.archive(id, nextArchived);
    updateThreadPreference(client, id, threadPreferenceUpdate({ isArchived: nextArchived }));
  }
  async function setArchive() {
    const nextArchived = !(newestPage?.preference?.isArchived ?? false);
    try {
      await applyArchive(nextArchived);
      showToast({
        message: nextArchived ? t('chat.archivedNotice') : t('chat.unarchivedNotice'),
        actionLabel: t('common.undo'),
        onAction: () => {
          void applyArchive(!nextArchived).catch(() => showToast({ message: t('chat.sendError') }));
        },
      });
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function blockCounterpart() {
    if (!newestPage?.otherUserId) return;
    const targetId = newestPage.otherUserId;
    try {
      await chatRepository.blockUser(targetId);
      setDetailsOpen(false);
      await navigate(path('messages'));
      showToast({
        message: t('chat.blockedNotice'),
        actionLabel: t('common.undo'),
        onAction: () => {
          void api
            .patch(`/users/${encodeURIComponent(targetId)}/unblock`)
            .catch(() => showToast({ message: t('chat.sendError') }));
        },
      });
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  function openStarred() {
    setDetailsOpen(false);
    setStarredOpen(true);
  }
  async function runConfirmed() {
    const pendingConfirm = confirm;
    if (!pendingConfirm) return;
    setConfirm(null);
    if (pendingConfirm.kind === 'deleteConversation') {
      try {
        await chatRepository.deleteConversation(id);
        await navigate(path('messages'));
      } catch {
        setActionError(t('chat.sendError'));
      }
      return;
    }
    if (pendingConfirm.kind === 'deleteMessage' && pendingConfirm.messageId) {
      const messageId = pendingConfirm.messageId;
      try {
        await chatRepository.deleteMessage(id, messageId);
        patchThreadMessage(client, id, messageId, deletedCopy);
      } catch {
        setActionError(t('chat.sendError'));
      }
      return;
    }
    if (pendingConfirm.kind === 'deleteSelected') {
      await deleteSelectedMessages();
      return;
    }
    if (pendingConfirm.kind === 'block') {
      await blockCounterpart();
      return;
    }
    if (pendingConfirm.kind === 'report' && newestPage?.otherUserId) {
      try {
        await chatRepository.reportUser(newestPage.otherUserId);
      } catch {
        setActionError(t('chat.sendError'));
      }
    }
  }
  function replyToSelected() {
    if (selectedIds.length !== 1) return;
    const target = messages.find((message) => message.id === selectedIds[0]);
    if (target) setReply(target);
    selection.clear();
  }
  function clearSelection() {
    selection.clear();
    selection.setTargets([]);
    setForwardOpen(false);
  }
  async function setTheme(theme: string) {
    try {
      await chatRepository.theme(id, theme);
      updateThreadPreference(client, id, threadPreferenceUpdate({ theme }));
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function acceptConversation() {
    try {
      await chatRepository.accept(id);
      patchConversationRecord(client, id, newestPage?.otherUser.displayName, {
        status: 'ACCEPTED',
      });
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function forwardSelected() {
    if (!selectedTargets.length || !selectedIds.length) return;
    const selected = messages.filter((message) => selectedIds.includes(message.id));
    if (
      !canForwardSelection(
        selected.length,
        selected.some((message) => message.viewOnce),
        selected.some((message) => message.deletedAt !== null) ||
          selected.length !== selectedIds.length,
      )
    ) {
      const key = selected.some((message) => message.viewOnce)
        ? 'chat.viewOnceForwardError'
        : selected.some((message) => message.deletedAt !== null) ||
            selected.length !== selectedIds.length
          ? 'chat.deletedForwardError'
          : 'chat.forwardLimitError';
      setActionError(t(key));
      return;
    }
    try {
      await chatRepository.forward(id, selectedIds, selectedTargets);
      selection.clear();
    } catch {
      setActionError(t('chat.sendError'));
    }
  }
  async function loadMoreForwardTargets() {
    try {
      await forwardTargetsQuery.fetchNextPage();
    } catch {
      setActionError(t('chat.loadError'));
    }
  }
  function toggleSelected(messageId: string, checked: boolean) {
    selection.toggle(messageId, checked);
  }

  const muted = newestPage?.preference?.muted ?? false;
  const status =
    newestPage?.threadType === 'ORDER'
      ? t('chat.order')
      : record?.status === 'PENDING'
        ? t('chat.pending')
        : newestPage
          ? t('chat.direct')
          : undefined;
  const locationPreview = locationMessageMetadata({
    latitude: locationLatitude,
    longitude: locationLongitude,
    address: locationAddress,
    accuracyMeters: locationAccuracy ?? 0,
    capturedAt: locationCapturedAt ?? new Date().toISOString(),
  });
  const loadError =
    transcriptQuery.isError ||
    (Boolean(galleryKind) && galleryQuery.isError) ||
    (starredOpen && starredQuery.isError) ||
    (forwardOpen && forwardTargetsQuery.isError)
      ? t('chat.loadError')
      : '';
  const recordError =
    recorder.failure === 'permission'
      ? t('chat.recordPermissionError')
      : recorder.failure === 'recorder'
        ? t('chat.recordUnsupported')
        : '';
  const error =
    actionError ||
    joinError ||
    recordError ||
    loadError ||
    (backgroundMedia.error !== null ? t('chat.mediaError') : '');
  const confirmMeta =
    confirm === null
      ? null
      : confirm.kind === 'deleteConversation'
        ? {
            title: t('chat.deleteConversation'),
            body: t('chat.confirmDeleteConversation'),
            actionLabel: t('common.delete'),
            danger: true,
          }
        : confirm.kind === 'deleteMessage'
          ? {
              title: t('chat.deleteMessage'),
              body: t('chat.confirmDeleteMessage'),
              actionLabel: t('common.delete'),
              danger: true,
            }
          : confirm.kind === 'deleteSelected'
            ? {
                title: t('chat.deleteSelected'),
                body: t('chat.confirmDeleteSelected'),
                actionLabel: t('common.delete'),
                danger: true,
              }
            : confirm.kind === 'block'
              ? {
                  title: t('chat.block'),
                  body: t('chat.confirmBlock'),
                  actionLabel: t('chat.block'),
                  danger: true,
                }
              : {
                  title: t('chat.report'),
                  body: t('chat.confirmReport'),
                  actionLabel: t('chat.report'),
                  danger: false,
                };
  const pending = send.isPending;
  return (
    <div className="mx-auto grid min-h-0 min-w-0 w-full flex-1 grid-cols-1 grid-rows-[minmax(0,1fr)] gap-3 p-3 text-ink sm:p-6 md:grid-cols-[320px_minmax(0,1fr)]">
      <ThreadSidebar conversations={sidebarConversations} activeId={id} />
      <section className="flex min-h-0 min-w-0 flex-col">
        <header className="flex shrink-0 flex-wrap items-center gap-2 surface p-3 sm:p-4">
          <Link
            className="icon-control"
            to={path('messages')}
            aria-label={t('common.back')}
            title={t('common.back')}
          >
            <Icon name="back" size={18} />
          </Link>
          <div className="min-w-0 flex-1 overflow-hidden">
            <h1 className="whitespace-nowrap font-display text-xl font-bold">
              {newestPage?.otherUser.displayName ?? t('chat.thread')}
            </h1>
            <p className="text-xs text-muted">
              {muted
                ? t('chat.muted')
                : presenceHidden
                  ? t('chat.presenceHidden')
                  : online
                    ? t('chat.online')
                    : typing
                      ? t('chat.typing')
                      : status}
            </p>
            {record?.product ? (
              <Link
                className="text-xs text-brand underline"
                to={path(pathsFor.product(record.product.id))}
              >
                {record.product.title}
              </Link>
            ) : null}
            {record?.orderInfo ? (
              <Link
                className="text-xs text-brand underline"
                to={path(pathsFor.order(record.orderInfo.id))}
              >
                {record.orderInfo.productTitle}
              </Link>
            ) : null}
          </div>
          <button
            className="icon-control"
            type="button"
            onClick={() => setDetailsOpen(true)}
            aria-label={t('chat.details')}
            title={t('chat.details')}
          >
            <Icon name="info" size={18} />
          </button>
          <button
            className="icon-control"
            type="button"
            onClick={() => setGalleryKind('IMAGE')}
            aria-label={t('chat.media')}
            title={t('chat.media')}
          >
            <Icon name="image" size={18} />
          </button>
          <button
            className="icon-control"
            type="button"
            onClick={openStarred}
            aria-label={t('chat.starred')}
            title={t('chat.starred')}
          >
            <Icon name="bookmark" size={18} />
          </button>
          <button
            className="icon-control"
            type="button"
            onClick={() => void setArchive()}
            aria-label={
              newestPage?.preference?.isArchived ? t('chat.unarchive') : t('chat.archive')
            }
            title={newestPage?.preference?.isArchived ? t('chat.unarchive') : t('chat.archive')}
          >
            <Icon name="archive" size={18} />
          </button>
          <button
            className="icon-control icon-control-danger"
            type="button"
            onClick={() => setConfirm({ kind: 'deleteConversation' })}
            aria-label={t('chat.deleteConversation')}
            title={t('chat.deleteConversation')}
          >
            <Icon name="trash" size={18} />
          </button>
        </header>
        {offline ? (
          <p role="status" className="mt-2 bg-surface-mid p-2 text-sm">
            {t('chat.socketOffline')}
          </p>
        ) : null}
        {error ? (
          <p role="alert" className="mt-2 bg-surface-high p-2 text-sm">
            {error}
          </p>
        ) : null}
        {record?.canAccept === true ? (
          <button
            className="ui-button ui-primary mt-2"
            type="button"
            onClick={() => void acceptConversation()}
          >
            {t('chat.accept')}
          </button>
        ) : null}
        <section
          ref={scrollNodeRef}
          aria-label={t('chat.thread')}
          className="mt-2 flex min-h-0 min-w-0 flex-1 flex-col gap-2 overflow-x-hidden overflow-y-auto border border-(--hairline) p-2 sm:p-4"
          style={
            backgroundImage
              ? { backgroundImage: `url("${backgroundImage}")`, backgroundSize: 'cover' }
              : undefined
          }
        >
          {transcriptQuery.hasNextPage ? (
            <button
              className="ui-button ui-secondary self-center"
              type="button"
              disabled={transcriptQuery.isFetchingNextPage}
              onClick={() => void loadOlder()}
            >
              {t('chat.loadOlder')}
            </button>
          ) : null}
          {messages.map((message) => (
            <MessageItem
              key={message.id}
              message={message}
              conversationId={id}
              locale={locale}
              userId={session.user?.id}
              userAvatar={session.user?.avatarUrl ?? null}
              userName={session.user?.displayName ?? ''}
              otherName={newestPage?.otherUser.displayName ?? ''}
              otherAvatar={newestPage?.otherUser.avatarUrl ?? null}
              selected={selectedIds.includes(message.id)}
              onToggle={toggleSelected}
              onReply={(target) => {
                setReply(target);
                selection.clear();
              }}
              onOpenExternal={(url) => void openExternal(url)}
            />
          ))}
          {!messages.length && !error ? (
            <p className="m-auto text-muted">{t('chat.emptyThread')}</p>
          ) : null}
        </section>
        <form className="mt-2 grid shrink-0 gap-2 surface p-3" onSubmit={submit}>
          {reply ? (
            <div className="flex items-center justify-between bg-surface-mid p-2 text-sm">
              <span className="truncate">
                {t('chat.reply')}: {reply.content ?? t('chat.media')}
              </span>
              <button type="button" className="underline" onClick={() => setReply(null)}>
                {t('chat.cancel')}
              </button>
            </div>
          ) : null}
          {selectedIds.length ? (
            <div className="flex flex-wrap items-center gap-2 bg-surface-mid p-2 text-sm">
              <span>{t('chat.selected', { count: selectedIds.length })}</span>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={clearSelection}
                aria-label={t('chat.cancel')}
                title={t('chat.cancel')}
              >
                <Icon name="close" size={16} />
              </button>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={replyToSelected}
                aria-label={t('chat.reply')}
                title={t('chat.reply')}
              >
                <Icon name="reply" size={16} />
              </button>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={() => void starSelected()}
                aria-label={t('chat.star')}
                title={t('chat.star')}
              >
                <Icon name="bookmark" size={16} />
              </button>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={() => void copySelected()}
                aria-label={t('chat.copy')}
                title={t('chat.copy')}
              >
                <Icon name="doc" size={16} />
              </button>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={() => void shareSelected()}
                aria-label={t('chat.share')}
                title={t('chat.share')}
              >
                <Icon name="send" size={16} />
              </button>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={() => setForwardOpen((open) => !open)}
                aria-label={t('chat.chooseRecipients')}
                title={t('chat.chooseRecipients')}
              >
                <Icon name="repeat" size={16} />
              </button>
              <button
                type="button"
                className="icon-control icon-control-sm"
                onClick={() => setConfirm({ kind: 'deleteSelected' })}
                aria-label={t('chat.deleteSelected')}
                title={t('chat.deleteSelected')}
              >
                <Icon name="trash" size={16} />
              </button>
              {forwardOpen ? (
                <>
                  <input
                    aria-label={t('chat.searchConversations')}
                    placeholder={t('chat.searchConversations')}
                    className="min-h-10 bg-surface-high p-2"
                    type="search"
                    value={forwardQuery}
                    onChange={(event) => setForwardQuery(event.currentTarget.value)}
                  />
                  {forwardTargetsQuery.data?.pages
                    .flatMap((page) => page.items)
                    .map((item: Conversation) => (
                      <label key={item.id} className="flex items-center gap-1">
                        <input
                          type="checkbox"
                          checked={selectedTargets.includes(item.id)}
                          onChange={(event) => {
                            const checked = event.currentTarget.checked;
                            selection.setTargets((targets) =>
                              checked
                                ? [...new Set([...targets, item.id])]
                                : targets.filter((target) => target !== item.id),
                            );
                          }}
                        />
                        {item.otherUser.displayName}{' '}
                        {item.product?.title ?? item.orderInfo?.productTitle ?? ''}
                      </label>
                    ))}
                  {forwardTargetsQuery.hasNextPage ? (
                    <button
                      type="button"
                      className="underline"
                      disabled={forwardTargetsQuery.isFetchingNextPage}
                      onClick={() => void loadMoreForwardTargets()}
                    >
                      {t('common.loadMore')}
                    </button>
                  ) : null}
                  <button
                    type="button"
                    className="ui-button ui-secondary"
                    disabled={!selectedTargets.length}
                    onClick={() => void forwardSelected()}
                  >
                    {t('chat.forward')}
                  </button>
                </>
              ) : null}
            </div>
          ) : null}
          <div className="emoji-wrap">
            <ComposerInput
              ref={inputRef}
              label={t('chat.message')}
              placeholder={t('chat.composerPlaceholder')}
              value={draft}
              disabled={pending}
              maxLength={5000}
              onChange={(value) => handleDraftChange(value)}
              onSubmit={sendDraft}
            />
            <div className="emoji-dock">
              <button type="button" className="emoji-trigger" aria-label={t('chat.reactions')}>
                <span className="sr-only">{t('chat.reactions')}</span>
              </button>
              <div className="emoji-picker" role="listbox">
                {CHAT_REACTIONS.map((emoji) => (
                  <button key={emoji} type="button" onClick={() => pickEmoji(emoji)}>
                    {emoji}
                  </button>
                ))}
              </div>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2 *:size-[38px] *:flex-none [&_.ui-icon-toggle]:border-(--edge) [&_.ui-icon-toggle]:bg-surface-mid">
            <label
              className="icon-control cursor-pointer"
              aria-label={t('chat.upload')}
              title={t('chat.upload')}
            >
              <Icon name="attach" size={18} />
              <input
                className="sr-only"
                type="file"
                accept="image/*,video/*,audio/*"
                disabled={pending}
                aria-label={t('chat.upload')}
                onChange={(event) => {
                  const file = event.currentTarget.files?.[0];
                  if (file?.type.startsWith('image/')) {
                    setImageToEdit(file);
                    setImageEdited(false);
                    setImageCaption('');
                  } else if (file?.type.startsWith('video/')) {
                    setVideoToSend(file);
                    setVideoCaption('');
                    setVideoViewOnce(viewOnce);
                  } else if (file) void upload(file);
                  event.currentTarget.value = '';
                }}
              />
            </label>
            <label
              className="ui-icon-toggle"
              title={t('chat.viewOnce')}
              aria-label={t('chat.viewOnce')}
            >
              <input
                type="checkbox"
                checked={viewOnce}
                onChange={(event) => setViewOnce(event.currentTarget.checked)}
                aria-label={t('chat.viewOnce')}
              />
              <Icon name="viewOnce" size={18} />
            </label>
            <button
              className="icon-control"
              type="button"
              onClick={shareLocation}
              aria-label={t('chat.location')}
              title={t('chat.location')}
            >
              <Icon name="pin" size={18} />
            </button>
            <button
              className="icon-control"
              type="button"
              onClick={() => void openProductPicker()}
              aria-label={t('chat.shareProduct')}
              title={t('chat.shareProduct')}
            >
              <Icon name="sell" size={18} />
            </button>
            {!recording ? (
              <button
                className="icon-control"
                type="button"
                onClick={() => void recorder.start()}
                aria-label={t('chat.record')}
                title={t('chat.record')}
              >
                <Icon name="mic" size={18} />
              </button>
            ) : (
              <span className="recording-pill" style={{ width: 'auto', height: 'auto' }}>
                <span className="recording-dot" aria-hidden="true" />
                {t('chat.recording')} {recorder.elapsedSeconds}s
                <button
                  className="icon-control"
                  type="button"
                  onClick={recorder.stop}
                  aria-label={t('chat.send')}
                  title={t('chat.send')}
                >
                  <Icon name="send" size={16} />
                </button>
                <button
                  className="icon-control icon-control-danger"
                  type="button"
                  onClick={recorder.cancel}
                  aria-label={t('chat.cancel')}
                  title={t('chat.cancel')}
                >
                  <Icon name="close" size={16} />
                </button>
              </span>
            )}
            <button
              className="icon-control icon-control-primary ml-auto"
              type="submit"
              disabled={pending || !draft.trim()}
              aria-label={t('chat.send')}
              title={t('chat.send')}
            >
              <Icon name="send" size={18} />
            </button>
          </div>
          {recorder.unsupported ? (
            <p role="status" className="text-xs text-muted">
              {t('chat.recordUnsupported')}
            </p>
          ) : null}
        </form>
      </section>
      <Dialog
        open={Boolean(galleryKind)}
        onClose={() => setGalleryKind(null)}
        title={t('chat.media')}
      >
        <nav className="my-3 flex flex-wrap gap-2">
          {(['IMAGE', 'VIDEO', 'AUDIO'] as const).map((type) => (
            <button
              key={type}
              className="ui-button ui-secondary"
              onClick={() => setGalleryKind(type)}
            >
              {type === 'IMAGE'
                ? t('chat.mediaImage')
                : type === 'VIDEO'
                  ? t('chat.mediaVideo')
                  : type === 'AUDIO'
                    ? t('chat.mediaAudio')
                    : null}
            </button>
          ))}
        </nav>
        <div className="grid max-h-[65svh] gap-3 overflow-auto">
          {galleryItems.map((message) =>
            message.attachmentUrl && isMediaType(message.type) ? (
              <AuthenticatedMedia
                key={message.id}
                src={message.attachmentUrl}
                type={
                  message.type === 'VIDEO' ? 'video' : message.type === 'AUDIO' ? 'audio' : 'image'
                }
                alt={t('chat.media')}
              />
            ) : null,
          )}
        </div>
        {galleryQuery.hasNextPage ? (
          <button
            className="ui-button ui-secondary mt-3"
            disabled={galleryQuery.isFetchingNextPage}
            onClick={() => void loadOlderGallery()}
          >
            {t('common.loadMore')}
          </button>
        ) : null}
      </Dialog>
      <Dialog open={starredOpen} onClose={() => setStarredOpen(false)} title={t('chat.starred')}>
        {starredQuery.data?.length ? (
          starredQuery.data.map((message) => (
            <p key={message.id} className="my-2 bg-surface-mid p-3">
              {message.content ?? t('chat.media')}
            </p>
          ))
        ) : (
          <p>{t('chat.starredEmpty')}</p>
        )}
      </Dialog>
      <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} title={t('chat.details')}>
        <div className="mb-4 mt-3 flex flex-wrap gap-2">
          {newestPage?.otherUserId ? (
            <Link
              className="icon-control"
              to={path(pathsFor.person(newestPage.otherUserId))}
              aria-label={`${t('chat.profile')}: ${newestPage.otherUser.displayName}`}
              title={`${t('chat.profile')}: ${newestPage.otherUser.displayName}`}
            >
              <Icon name="user" size={18} />
            </Link>
          ) : null}
          <button
            type="button"
            className="icon-control"
            aria-pressed={muted}
            onClick={() => void toggleMute()}
            aria-label={muted ? t('chat.unmute') : t('chat.mute')}
            title={muted ? t('chat.unmute') : t('chat.mute')}
          >
            <Icon name={muted ? 'volumeOn' : 'volumeOff'} size={18} />
          </button>
          <button
            type="button"
            className="icon-control"
            aria-pressed={presenceHidden}
            onClick={togglePresenceHiddenChoice}
            aria-label={presenceHidden ? t('chat.showPresence') : t('chat.hidePresence')}
            title={presenceHidden ? t('chat.showPresence') : t('chat.hidePresence')}
          >
            <Icon name={presenceHidden ? 'eye' : 'eyeOff'} size={18} />
          </button>
          <button
            type="button"
            className="icon-control"
            onClick={() => {
              setDetailsOpen(false);
              setGalleryKind('IMAGE');
            }}
            aria-label={t('chat.media')}
            title={t('chat.media')}
          >
            <Icon name="image" size={18} />
          </button>
          <button
            type="button"
            className="icon-control"
            onClick={openStarred}
            aria-label={t('chat.starred')}
            title={t('chat.starred')}
          >
            <Icon name="bookmark" size={18} />
          </button>
          {newestPage?.otherUserId ? (
            <button
              type="button"
              className="icon-control icon-control-danger"
              onClick={() => setConfirm({ kind: 'block' })}
              aria-label={t('chat.block')}
              title={t('chat.block')}
            >
              <Icon name="shield" size={18} />
            </button>
          ) : null}
          {newestPage?.otherUserId ? (
            <button
              type="button"
              className="icon-control"
              onClick={() => {
                setDetailsOpen(false);
                setConfirm({ kind: 'report' });
              }}
              aria-label={t('chat.report')}
              title={t('chat.report')}
            >
              <Icon name="doc" size={18} />
            </button>
          ) : null}
        </div>
        <Select
          label={t('chat.theme')}
          value={newestPage?.preference?.theme ?? 'DEFAULT'}
          onChange={(event) => void setTheme(event.currentTarget.value)}
        >
          {CHAT_THEMES.map((theme) => (
            <option key={theme} value={theme}>
              {t(`chat.theme.${theme}`)}
            </option>
          ))}
        </Select>
        <div className="mt-[14px] mb-[2px] flex items-center gap-2">
          <label
            className="icon-control cursor-pointer"
            aria-label={t('chat.uploadBackground')}
            title={t('chat.uploadBackground')}
          >
            <Icon name="image" size={18} />
            <input
              className="sr-only"
              type="file"
              accept="image/png,image/jpeg,image/webp,image/gif"
              aria-label={t('chat.uploadBackground')}
              onChange={(event) => {
                const file = event.currentTarget.files?.[0];
                if (file) void uploadBackground(file);
                event.currentTarget.value = '';
              }}
            />
          </label>
          <input
            aria-label={t('chat.background')}
            className="min-w-0 flex-1 bg-surface-high p-2"
            value={background}
            onChange={(event) => setBackgroundOverride(event.currentTarget.value)}
          />
          <button
            className="icon-control"
            type="button"
            onClick={() => void saveBackground()}
            aria-label={t('chat.saveBackground')}
            title={t('chat.saveBackground')}
          >
            <Icon name="check" size={18} />
          </button>
        </div>
      </Dialog>
      <Dialog
        open={confirm !== null}
        onClose={() => setConfirm(null)}
        title={confirmMeta?.title ?? t('common.confirm')}
        actions={
          confirmMeta ? (
            <>
              <Button variant="secondary" onClick={() => setConfirm(null)}>
                {t('common.cancel')}
              </Button>
              <Button
                variant={confirmMeta.danger ? 'danger' : 'primary'}
                onClick={() => void runConfirmed()}
              >
                {confirmMeta.actionLabel}
              </Button>
            </>
          ) : undefined
        }
      >
        {confirmMeta?.body}
      </Dialog>
      <Dialog
        open={imageToEdit !== null}
        onClose={() => setImageToEdit(null)}
        title={t('chat.editImage')}
      >
        {imageToEdit && !imageEdited ? (
          <ImageEditor
            file={imageToEdit}
            onCancel={() => setImageToEdit(null)}
            onSave={(file) => {
              setImageToEdit(file);
              setImageEdited(true);
            }}
          />
        ) : null}
        {imageToEdit && imageEdited ? (
          <>
            <label className="ui-field">
              {t('chat.caption')}
              <textarea
                className="min-h-20"
                maxLength={5000}
                value={imageCaption}
                onChange={(event) => setImageCaption(event.currentTarget.value)}
              />
            </label>
            <button
              type="button"
              className="ui-button ui-primary mt-3"
              disabled={pending}
              onClick={() => {
                const file = imageToEdit;
                setImageToEdit(null);
                void upload(file, undefined, imageCaption);
              }}
            >
              {t('chat.send')}
            </button>
          </>
        ) : null}
      </Dialog>
      <Dialog
        open={productsOpen}
        onClose={() => setProductsOpen(false)}
        title={t('chat.shareProduct')}
      >
        <input
          className="min-h-10 w-full bg-surface-high p-2"
          aria-label={t('chat.searchProducts')}
          value={productQuery}
          onChange={(event) => setProductQuery(event.currentTarget.value)}
          type="search"
        />
        {products
          .filter((product) =>
            product.title.toLocaleLowerCase().includes(productQuery.toLocaleLowerCase()),
          )
          .map((product) => (
            <button
              key={product.id}
              type="button"
              className="block w-full bg-surface-mid p-3 text-left"
              onClick={() => void sendProductCard(product)}
            >
              {product.title}
            </button>
          ))}
        {!products.length ? <p role="status">{t('chat.noProducts')}</p> : null}
      </Dialog>
      <Dialog
        open={videoToSend !== null}
        onClose={() => setVideoToSend(null)}
        title={t('chat.videoPreview')}
      >
        {videoUrl ? (
          <video className="max-h-96 max-w-full" src={videoUrl} controls muted playsInline />
        ) : null}
        <label className="ui-field mt-3">
          {t('chat.caption')}
          <textarea
            className="min-h-20"
            maxLength={5000}
            value={videoCaption}
            onChange={(event) => setVideoCaption(event.currentTarget.value)}
          />
        </label>
        <label className="mt-2 flex items-center gap-2">
          <input
            type="checkbox"
            checked={videoViewOnce}
            onChange={(event) => setVideoViewOnce(event.currentTarget.checked)}
          />
          {t('chat.viewOnce')}
        </label>
        <button
          className="ui-button ui-primary mt-3"
          type="button"
          disabled={pending || !videoToSend}
          onClick={() => {
            if (!videoToSend) return;
            const file = videoToSend;
            setVideoToSend(null);
            void upload(file, undefined, videoCaption, videoViewOnce);
          }}
        >
          {t('chat.send')}
        </button>
      </Dialog>
      <Dialog open={locationOpen} onClose={() => setLocationOpen(false)} title={t('chat.location')}>
        <p className="mb-3 text-sm text-muted">{t('chat.mapPickHint')}</p>
        <p className="mb-3 text-xs text-muted">{t('chat.meetupNote')}</p>
        <LocationPicker
          key={`${locationLatitude},${locationLongitude}`}
          latitude={locationLatitude}
          longitude={locationLongitude}
          onPick={(point) => {
            setLocationLatitude(point.latitude);
            setLocationLongitude(point.longitude);
            setLocationAccuracy(point.accuracyMeters);
            setLocationCapturedAt(point.capturedAt);
            setLocationError('');
          }}
          onGeolocationError={() => setLocationError(t('chat.locationPermissionError'))}
          useCurrentLabel={t('chat.useCurrentLocation')}
        />
        <p className="mt-2 text-sm text-muted">{t('chat.locationMeasuredHint')}</p>
        {locationAccuracy !== undefined && locationCapturedAt ? (
          <p role="status" className="mt-2 text-sm text-muted">
            {t('chat.locationMeasurement', {
              accuracy: locationAccuracy,
              capturedAt: new Date(locationCapturedAt).toLocaleString(locale),
            })}
          </p>
        ) : null}
        <label className="mt-2 grid gap-1">
          {t('chat.placeName')}
          <input
            className="min-h-11 bg-surface-high p-2"
            type="text"
            maxLength={500}
            value={locationAddress}
            onChange={(event) => {
              setLocationAddress(event.currentTarget.value);
              setLocationError('');
            }}
          />
        </label>
        {locationError ? (
          <p role="alert" className="mt-2 text-danger">
            {locationError}
          </p>
        ) : null}
        <button
          type="button"
          className="ui-button ui-primary mt-3"
          disabled={!locationPreview || pending}
          onClick={sendChosenLocation}
        >
          {t('chat.sendLocation')}
        </button>
      </Dialog>
    </div>
  );
}

function ThreadPage() {
  const { id = '' } = useParams();
  const { user } = useSession();
  // Keyed remount: a conversation switch is a fresh mount, replacing the old
  // manual transcript/message reset block with plain component state.
  return <Thread key={`${user?.id}:${id}`} />;
}
export default function ChatThreadPage() {
  return (
    <RequireAuth>
      <ThreadPage />
    </RequireAuth>
  );
}
