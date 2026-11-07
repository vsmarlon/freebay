import { useCallback, useRef, useState, type FormEvent } from 'react';
import { Link, useLocation, useNavigate, useParams } from 'react-router';
import { RequireAuth, useSession } from '../../core/session';
import { Button, Dialog, Icon, Select } from '../../components/index';
import { useToast } from '../../components/toast';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import { api } from '../../core/api';
import { ChatComposer } from './chat-composer';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import { chatRepository } from './repository';
import { CHAT_REACTIONS, CHAT_THEMES, canForwardSelection, hasValidCoordinates, locationMessageMetadata, mergeMessages, mediaMessagePayload, replyPreview, shouldRefreshReadState, type ChatMessage, type Conversation, type MediaKind, type Transcript } from './model';
import { createChatSocket, type ChatSocket } from './socket';
import { AuthenticatedMedia } from './media';
import { ImageEditor } from '../../components/image-editor';

const catalogs = { en, 'pt-BR': ptBR };
const uuid = () => crypto.randomUUID();
const isMediaType = (type: string): type is MediaKind => type === 'IMAGE' || type === 'VIDEO' || type === 'AUDIO';
const deletedCopy = (message: ChatMessage): ChatMessage => ({ ...message, deletedAt: new Date().toISOString(), content: null, attachmentUrl: null, metadata: null });

export async function startConversation(targetUserId: string, productId?: string) {
  return chatRepository.start(targetUserId, productId);
}

function Thread() {
  const { id = '', locale = 'pt-BR' } = useParams();
  const session = useSession();
  const { t, path } = useI18n(catalogs);
  const { show: showToast } = useToast();
  const navigate = useNavigate();
  const location = useLocation();
  const [transcript, setTranscript] = useState<Transcript | null>(null);
  const [conversation, setConversation] = useState<Conversation | null>(null);
  const [sidebarConversations, setSidebarConversations] = useState<Conversation[]>([]);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [draft, setDraft] = useState('');
  const [reply, setReply] = useState<ChatMessage | null>(null);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState('');
  const [offline, setOffline] = useState(false);
  const [typing, setTyping] = useState(false);
  const [online, setOnline] = useState(false);
  const [gallery, setGallery] = useState<MediaKind | null>(null);
  const [galleryItems, setGalleryItems] = useState<ChatMessage[]>([]);
  const [galleryCursor, setGalleryCursor] = useState<string | null>(null);
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [selectedTargets, setSelectedTargets] = useState<string[]>([]);
  const [forwardOpen, setForwardOpen] = useState(false);
  const [forwardQuery, setForwardQuery] = useState('');
  const [forwardPage, setForwardPage] = useState<{ items: Conversation[]; nextCursor: string | null } | null>(null);
  const [starred, setStarred] = useState<ChatMessage[] | null>(null);
  const [starredIds, setStarredIds] = useState<Set<string>>(() => new Set());
  const [recording, setRecording] = useState(false);
  const [recordUnsupported, setRecordUnsupported] = useState(false);
  const [viewOnce, setViewOnce] = useState(false);
  const [background, setBackground] = useState('');
  const [backgroundImage, setBackgroundImage] = useState<string | null>(null);
  const [imageToEdit, setImageToEdit] = useState<File | null>(null);
  const [imageEdited, setImageEdited] = useState(false);
  const [imageCaption, setImageCaption] = useState('');
  const [videoToSend, setVideoToSend] = useState<File | null>(null);
  const [videoUrl, setVideoUrl] = useState<string | null>(null);
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
  const [confirm, setConfirm] = useState<{ kind: 'deleteConversation' | 'deleteMessage' | 'deleteSelected' | 'report' | 'block'; messageId?: string } | null>(null);
  const [muted, setMuted] = useState(false);
  const [reactionsOpen, setReactionsOpen] = useState<string | null>(null);
  const [presenceHidden, setPresenceHidden] = useState(false);
  const [productsOpen, setProductsOpen] = useState(false);
  const [products, setProducts] = useState<Array<{ id: string; title: string; price: number; imageUrl: string | null }>>([]);
  const [productQuery, setProductQuery] = useState('');
  const scrollNodeRef = useRef<HTMLDivElement | null>(null);
  const scrollRef = useCallback((node: HTMLDivElement | null) => {
    scrollNodeRef.current = node;
    if (!node) return;
    if (previousHeight.current !== null) {
      node.scrollTop += node.scrollHeight - previousHeight.current;
      previousHeight.current = null;
    } else node.scrollTop = node.scrollHeight;
  }, [messages.length]);
  const socketRef = useRef<ChatSocket | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const chunksRef = useRef<Blob[]>([]);
  const previousHeight = useRef<number | null>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const textRef = useRef(t);
  textRef.current = t;
  const recordingStartedAt = useRef(0);
  const recordingLimit = useRef<number | null>(null);
  const cancelRecording = useRef(false);
  const typingTimer = useRef<number | null>(null);
  const activeContext = useRef({ id, userId: session.user?.id });
  activeContext.current = { id, userId: session.user?.id };
  const inquiryConsumed = useRef(false);
  const draftEdited = useRef(false);

  const threadLoadRef = useCallback((node: HTMLElement | null) => {
    if (!node) return;
    if (!session.user?.id) { setPresenceHidden(false); }
    else {
      const key = `freebay.chat.presence-hidden.${session.user.id}`;
      try {
        const saved = localStorage.getItem(key);
        const legacy = saved === null ? localStorage.getItem(`freebay.chat.muted.${session.user.id}`) : null;
        const hidden = JSON.parse(saved ?? legacy ?? '[]');
        setPresenceHidden(Array.isArray(hidden) && hidden.includes(id));
      } catch { setPresenceHidden(false); }
    }
    const controller = new AbortController();
    setTranscript(null); setConversation(null); setMessages([]); setError(''); setReply(null); setSelectedIds([]); setSelectedTargets([]); setStarred(null); setStarredIds(new Set()); setGallery(null); setGalleryItems([]); setGalleryCursor(null); setViewOnce(false); setImageToEdit(null); setImageEdited(false); setVideoToSend(null); setVideoCaption(''); setLocationOpen(false); setLocationLatitude(''); setLocationLongitude(''); setLocationAddress(''); setLocationAccuracy(undefined); setLocationCapturedAt(undefined); setLocationError(''); setDraft(''); setMuted(false); draftEdited.current = false; inquiryConsumed.current = false; setBackground(''); setBackgroundImage(null); setRecording(false); setPending(false);
    cancelRecording.current = true;
    if (recordingLimit.current !== null) window.clearTimeout(recordingLimit.current);
    if (recorderRef.current?.state === 'recording') recorderRef.current.stop();
    streamRef.current?.getTracks().forEach((track) => track.stop());
    streamRef.current = null;
    void chatRepository.transcript(id, undefined, controller.signal).then((data) => {
      setTranscript(data); setMessages(data.messages); setBackground(data.preference?.backgroundUrl ?? '');
      void (async () => {
        let page = await chatRepository.conversations({ q: data.otherUser.displayName, signal: controller.signal });
        let found = page.items.find((item) => item.id === id);
        while (!found && page.nextCursor && !controller.signal.aborted) {
          page = await chatRepository.conversations({ q: data.otherUser.displayName, cursor: page.nextCursor, signal: controller.signal });
          found = page.items.find((item) => item.id === id);
        }
        if (found && !controller.signal.aborted) setConversation(found);
      })().catch(() => {});
    }).catch(() => { if (!controller.signal.aborted) setError(textRef.current('chat.loadError')); });
    void chatRepository.conversations({ signal: controller.signal }).then((page) => setSidebarConversations(page.items)).catch(() => {});
    return () => controller.abort();
  }, [id, session.user?.id]);



  const inquiryRef = useCallback((node: HTMLElement | null) => {
    if (!node || !transcript || !conversation || inquiryConsumed.current) return;
    const state = location.state as { productInquiryDraft?: { productId?: string; targetUserId?: string } } | null;
    const inquiry = state?.productInquiryDraft;
    if (!inquiry) return;
    inquiryConsumed.current = true;
    if (!draftEdited.current && !draft && inquiry.productId === conversation.product?.id && inquiry.targetUserId === transcript.otherUserId) {
      setDraft(t('chat.productInquiryGreeting'));
    }
    void navigate(`${location.pathname}${location.search}${location.hash}`, { replace: true, state: null });
  }, [conversation, draft, location, navigate, transcript, t]);

  // muted preference derived during render below (state synced via inquiryRef's deps? no — derive here)
  const _muted = transcript?.preference?.muted ?? false;
  if (_muted !== muted) setMuted(_muted);

  const forwardRef = useCallback((node: HTMLElement | null) => {
    if (!node || !forwardOpen) return;
    const controller = new AbortController();
    const timer = window.setTimeout(() => {
      void chatRepository.conversations({ q: forwardQuery, signal: controller.signal }).then(setForwardPage).catch(() => { if (!controller.signal.aborted) setError(textRef.current('chat.loadError')); });
    }, 180);
    return () => { window.clearTimeout(timer); controller.abort(); };
  }, [forwardOpen, forwardQuery]);

  const socketBindRef = useCallback((node: HTMLElement | null) => {
    if (!node || !id || !session.user) return;
    const socket = createChatSocket();
    socketRef.current = socket;
    let catchup: AbortController | null = null;
    const refreshCanonicalReadState = () => {
      catchup?.abort();
      const controller = new AbortController(); catchup = controller;
      const accountId = session.user?.id;
      void chatRepository.transcript(id, undefined, controller.signal).then((data) => {
        if (controller.signal.aborted || socketRef.current !== socket || activeContext.current.id !== id || activeContext.current.userId !== accountId) return;
        setTranscript(data); setMessages((current) => mergeMessages(current, data.messages)); setBackground(data.preference?.backgroundUrl ?? ''); setMuted(data.preference?.muted ?? false);
      }).catch(() => {});
    };
    const join = () => { setOffline(false); socket.emit('join_conversation', { conversationId: id }, (response: { error?: string } | undefined) => { if (response?.error) setError(response.error); }); refreshCanonicalReadState(); };
    socket.on('connect', join);
    socket.on('disconnect', () => { setOffline(true); setTyping(false); setOnline(false); });
    socket.on('connect_error', () => setOffline(true));
    socket.on('new_message', (message: ChatMessage) => { if (message.conversationId === id) { setMessages((current) => mergeMessages(current, [message])); if (message.senderId !== session.user?.id) void chatRepository.markRead(id).catch(() => {}); } });
    socket.on('messages_read', (event: { conversationId: string; readerId: string }) => {
      if (shouldRefreshReadState(event, id, session.user?.id)) refreshCanonicalReadState();
    });
    socket.on('message_deleted', ({ messageId }: { messageId: string }) => setMessages((current) => current.map((message) => message.id === messageId ? deletedCopy(message) : message)));
    socket.on('reaction_updated', ({ messageId, reactions }: { messageId: string; reactions: NonNullable<ChatMessage['reactions']> }) => setMessages((current) => current.map((message) => message.id === messageId ? { ...message, reactions } : message)));
    socket.on('user_typing', ({ userId }: { userId: string }) => { if (userId === transcript?.otherUserId) setTyping(true); });
    socket.on('user_stopped_typing', ({ userId }: { userId: string }) => { if (userId === transcript?.otherUserId) setTyping(false); });
    socket.on('user_online', ({ userId }: { userId: string }) => { if (userId === transcript?.otherUserId) setOnline(true); });
    socket.on('user_offline', ({ userId }: { userId: string }) => { if (userId === transcript?.otherUserId) setOnline(false); });
    socket.connect();
    return () => {
      socket.emit('typing_stop', { conversationId: id });
      socket.emit('leave_conversation', { conversationId: id });
      catchup?.abort();
      socket.removeAllListeners(); socket.disconnect();
      if (socketRef.current === socket) socketRef.current = null;
    };
  }, [id, session.user, transcript?.otherUserId]);



  const backgroundRef = useCallback((node: HTMLElement | null) => {
    if (!node) return;
    if (!background) { setBackgroundImage(null); return; }
    if (/^data:image\/(?:png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+$/.test(background)) { setBackgroundImage(background); return; }
    let objectUrl: string | null = null;
    const controller = new AbortController();
    if (!background.startsWith('/media/background/')) { setBackgroundImage(null); return () => controller.abort(); }
    void api.blob(background, { signal: controller.signal }).then((blob) => {
      if (!controller.signal.aborted) { objectUrl = URL.createObjectURL(blob); setBackgroundImage(objectUrl); }
    }).catch(() => { if (!controller.signal.aborted) setError(textRef.current('chat.mediaError')); });
    return () => { controller.abort(); if (objectUrl) URL.revokeObjectURL(objectUrl); };
  }, [background, session.user?.id]);

  const videoRef2 = useCallback((node: HTMLElement | null) => {
    if (!node) return;
    if (!videoToSend) { setVideoUrl(null); return; }
    const url = URL.createObjectURL(videoToSend);
    setVideoUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [videoToSend]);

  const unmountRef = useCallback((node: HTMLElement | null) => {
    if (!node) return;
    return () => {
      if (typingTimer.current !== null) window.clearTimeout(typingTimer.current);
      if (recordingLimit.current !== null) window.clearTimeout(recordingLimit.current);
      cancelRecording.current = true;
      if (recorderRef.current?.state === 'recording') recorderRef.current.stop();
      streamRef.current?.getTracks().forEach((track) => track.stop());
    };
  }, []);

  const loadOlder = useCallback(async () => {
    if (!transcript?.nextCursor || pending) return;
    const scroll = scrollNodeRef.current;
    previousHeight.current = scroll?.scrollHeight ?? 0;
    setPending(true);
    try {
      const older = await chatRepository.transcript(id, transcript.nextCursor);
      setMessages((current) => mergeMessages(older.messages, current));
      setTranscript((current) => current ? { ...current, hasMore: older.hasMore, nextCursor: older.nextCursor } : current);
    } catch { setError(t('chat.loadError')); }
    finally { setPending(false); }
  }, [id, pending, transcript, t]);

  async function send(payload: Parameters<typeof chatRepository.send>[1]) {
    setError(''); setPending(true);
    try {
      const saved = await chatRepository.send(id, payload);
      setMessages((current) => mergeMessages(current, [saved]));
      setDraft(''); setReply(null); setViewOnce(false);
      socketRef.current?.emit('typing_stop', { conversationId: id });
      inputRef.current?.focus();
    } catch { setError(t('chat.sendError')); }
    finally { setPending(false); }
  }
  function handleDraftChange(value: string) {
    draftEdited.current = true;
    setDraft(value);
    socketRef.current?.emit(value ? 'typing' : 'typing_stop', { conversationId: id });
    if (typingTimer.current !== null) window.clearTimeout(typingTimer.current);
    if (value) typingTimer.current = window.setTimeout(() => socketRef.current?.emit('typing_stop', { conversationId: id }), 1500);
  }
  function sendDraft() { const content = draft.trim(); if (!content || pending) return; void send({ content, type: 'TEXT', clientMessageId: uuid(), ...(reply ? { replyToId: reply.id } : {}) }); }
  function submit(event: FormEvent) { event.preventDefault(); sendDraft(); }

  async function upload(file: File, durationMs?: number, caption?: string, viewOnceOverride = viewOnce) {
    setPending(true); setError('');
    try {
      const { url } = await chatRepository.upload(file);
      const type: MediaKind = file.type.startsWith('image/') ? 'IMAGE' : file.type.startsWith('video/') ? 'VIDEO' : 'AUDIO';
      await send({ ...mediaMessagePayload({ type, attachmentUrl: url, viewOnce: viewOnceOverride, durationMs }), clientMessageId: uuid(), ...(caption?.trim() ? { content: caption.trim() } : {}), ...(reply ? { replyToId: reply.id } : {}) });
    } catch { setError(t('chat.sendError')); setPending(false); }
  }
  async function toggleMute() {
    const context = { id, userId: session.user?.id };
    try {
      await chatRepository.mute(context.id, !muted);
      const controller = new AbortController();
      const canonical = await chatRepository.transcript(context.id, undefined, controller.signal);
      if (activeContext.current.id === context.id && activeContext.current.userId === context.userId) { setTranscript(canonical); setMuted(canonical.preference?.muted ?? false); }
    } catch { if (activeContext.current.id === context.id && activeContext.current.userId === context.userId) setError(t('chat.sendError')); }
  }

  async function uploadBackground(file: File) {
    if (!file.type.startsWith('image/')) return;
    try {
      const { url } = await chatRepository.upload(file, 'background');
      await chatRepository.background(id, url);
      setBackground(url);
    } catch { setError(t('chat.sendError')); }
  }

  async function loadOlderMedia() {
    if (!gallery || !galleryCursor) return;
    setPending(true);
    try { const page = await chatRepository.media(id, gallery, galleryCursor); setGalleryItems((current) => mergeMessages(current, page.messages)); setGalleryCursor(page.nextCursor); }
    catch { setError(t('chat.loadError')); }
    finally { setPending(false); }
  }
  async function toggleReaction(message: ChatMessage, emoji: string) {
    try { const result = await chatRepository.react(id, message.id, emoji); setMessages((current) => current.map((item) => item.id === message.id ? { ...item, reactions: result.reactions } : item)); }
    catch { setError(t('chat.sendError')); }
  }
  async function toggleStar(message: ChatMessage) {
    try {
      const result = await chatRepository.star(id, message.id);
      setStarredIds((current) => { const next = new Set(current); if (result.starred) next.add(message.id); else next.delete(message.id); return next; });
    } catch { setError(t('chat.sendError')); }
  }
  async function copySelected() {
    const content = messages.filter((message) => selectedIds.includes(message.id) && !message.viewOnce && !message.deletedAt).map((message) => message.content ?? '').filter(Boolean).join('\n');
    if (!content) return;
    try { await navigator.clipboard.writeText(content); setSelectedIds([]); }
    catch { setError(t('chat.clipboardError')); }
  }
  async function shareSelected() {
    const content = messages.filter((message) => selectedIds.includes(message.id) && !message.viewOnce && !message.deletedAt).map((message) => message.content ?? '').filter(Boolean).join('\n');
    if (!content || !navigator.share) { setError(t('chat.shareUnsupported')); return; }
    try { await navigator.share({ text: content }); setSelectedIds([]); }
    catch (cause) { if (!(cause instanceof DOMException && cause.name === 'AbortError')) setError(t('chat.sendError')); }
  }
  async function deleteSelectedMessages() {
    const deletable = messages.filter((message) => selectedIds.includes(message.id) && message.senderId === session.user?.id && !message.deletedAt);
    if (!deletable.length) return;
    const results = await Promise.allSettled(deletable.map((message) => chatRepository.deleteMessage(id, message.id)));
    const removed = new Set(deletable.filter((_, index) => results[index].status === 'fulfilled').map((message) => message.id));
    setMessages((items) => items.map((message) => removed.has(message.id) ? deletedCopy(message) : message));
    setSelectedIds([]);
    if (results.some((result) => result.status === 'rejected')) setError(t('chat.sendError'));
  }
  async function starSelected() {
    try { for (const messageId of selectedIds) { const result = await chatRepository.star(id, messageId); setStarredIds((current) => { const next = new Set(current); if (result.starred) next.add(messageId); else next.delete(messageId); return next; }); } setSelectedIds([]); }
    catch { setError(t('chat.sendError')); }
  }
  async function openProductPicker() {
    try { const result = await chatRepository.myProducts(); setProducts(result.products); setProductsOpen(true); }
    catch { setError(t('chat.loadError')); }
  }
  async function sendProductCard(product: (typeof products)[number]) {
    await send({ type: 'PRODUCT_CARD', clientMessageId: uuid(), metadata: { productId: product.id, title: product.title, price: product.price, imageUrl: product.imageUrl } });
    setProductsOpen(false); setProductQuery('');
  }
  async function openExternal(url: string) {
    try {
      const parsed = new URL(url);
      if (!['https:', 'http:'].includes(parsed.protocol)) throw new Error('unsupported');
      const result = await chatRepository.verifyUrl(parsed.href);
      if (!result.isSafe || !window.confirm(t('chat.openLink') + '?\n' + result.normalizedUrl)) { setError(t('chat.unsafeLink')); return; }
      window.open(result.normalizedUrl, '_blank', 'noopener,noreferrer');
    } catch { setError(t('chat.unsafeLink')); }
  }
  function togglePresenceHidden() {
    if (!session.user?.id) return;
    const key = `freebay.chat.presence-hidden.${session.user.id}`;
    let ids: string[] = [];
    try { const saved: unknown = JSON.parse(localStorage.getItem(key) ?? localStorage.getItem(`freebay.chat.muted.${session.user.id}`) ?? '[]'); if (Array.isArray(saved)) ids = saved.filter((value): value is string => typeof value === 'string'); } catch { /* use an empty local preference */ }
    const next = presenceHidden ? ids.filter((chatId) => chatId !== id) : [...new Set([...ids, id])];
    try { localStorage.setItem(key, JSON.stringify(next)); setPresenceHidden(!presenceHidden); }
    catch { setError(t('chat.sendError')); }
  }
  function shareLocation() { setLocationError(''); setLocationOpen(true); }
  function useCurrentLocation() {
    const context = { id, userId: session.user?.id };
    setLocationLatitude(''); setLocationLongitude(''); setLocationAccuracy(undefined); setLocationCapturedAt(undefined); setLocationError('');
    if (!navigator.geolocation) { setLocationError(t('chat.locationError')); return; }
    navigator.geolocation.getCurrentPosition(({ coords, timestamp }) => {
      if (activeContext.current.id !== context.id || activeContext.current.userId !== context.userId) return;
      const capturedAt = new Date(timestamp);
      if (!Number.isFinite(coords.latitude) || !Number.isFinite(coords.longitude) || !Number.isFinite(coords.accuracy) || !Number.isFinite(timestamp) || Number.isNaN(capturedAt.getTime())) { setLocationError(t('chat.locationError')); return; }
      const measured = locationMessageMetadata({ latitude: String(coords.latitude), longitude: String(coords.longitude), address: '', accuracyMeters: coords.accuracy, capturedAt: capturedAt.toISOString() });
      if (!measured) { setLocationError(t('chat.locationError')); return; }
      setLocationError('');
      setLocationLatitude(String(measured.latitude)); setLocationLongitude(String(measured.longitude));
      setLocationAccuracy(measured.accuracyMeters); setLocationCapturedAt(measured.capturedAt);
    }, (failure) => { if (activeContext.current.id !== context.id || activeContext.current.userId !== context.userId) return; setLocationLatitude(''); setLocationLongitude(''); setLocationAccuracy(undefined); setLocationCapturedAt(undefined); setLocationError(failure.code === 1 ? t('chat.locationPermissionError') : t('chat.locationError')); }, { enableHighAccuracy: true, timeout: 10000 });
  }
  function sendChosenLocation() {
    const metadata = locationMessageMetadata({ latitude: locationLatitude, longitude: locationLongitude, address: locationAddress, ...(locationAccuracy !== undefined ? { accuracyMeters: locationAccuracy } : {}), ...(locationCapturedAt ? { capturedAt: locationCapturedAt } : {}) });
    if (!metadata) { setLocationError(t('chat.locationInvalid')); return; }
    setLocationError('');
    setLocationOpen(false);
    void send({ type: 'LOCATION', clientMessageId: uuid(), metadata });
  }
  async function startRecording() {
    if (!navigator.mediaDevices?.getUserMedia || typeof MediaRecorder === 'undefined') { setRecordUnsupported(true); return; }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;
      const mimeType = ['audio/webm', 'audio/ogg', 'audio/mp4'].find((type) => MediaRecorder.isTypeSupported(type));
      if (!mimeType) { stream.getTracks().forEach((track) => track.stop()); streamRef.current = null; setRecordUnsupported(true); return; }
      const recorder = new MediaRecorder(stream, { mimeType });
      recorderRef.current = recorder; chunksRef.current = []; cancelRecording.current = false;
      recorder.ondataavailable = (event) => { if (event.data.size) chunksRef.current.push(event.data); };
      recorder.onstop = () => {
        stream.getTracks().forEach((track) => track.stop()); streamRef.current = null;
        const blob = new Blob(chunksRef.current, { type: mimeType });
        const durationMs = Math.min(60_000, Math.max(1, Math.round(performance.now() - recordingStartedAt.current)));
        const extension = mimeType === 'audio/ogg' ? 'ogg' : mimeType === 'audio/mp4' ? 'm4a' : 'weba';
        if (!cancelRecording.current && blob.size) void upload(new File([blob], `voice-${Date.now()}.${extension}`, { type: mimeType }), durationMs);
        if (recordingLimit.current !== null) window.clearTimeout(recordingLimit.current);
        recordingLimit.current = null;
        chunksRef.current = []; setRecording(false);
      };
      recordingStartedAt.current = performance.now(); recorder.start(); setRecording(true);
      recordingLimit.current = window.setTimeout(() => { if (recorder.state === 'recording') recorder.stop(); }, 60_000);
    } catch (cause) { setRecordUnsupported(true); setError(cause instanceof DOMException && cause.name === 'NotAllowedError' ? t('chat.recordPermissionError') : t('chat.recordUnsupported')); }
  }
  async function applyArchive(nextArchived: boolean) {
    await chatRepository.archive(id, nextArchived);
    setTranscript((current) => current ? { ...current, preference: { theme: 'DEFAULT', backgroundUrl: null, muted: false, ...current.preference, isArchived: nextArchived } } : current);
  }
  async function setArchive() {
    const nextArchived = !(transcript?.preference?.isArchived ?? false);
    try {
      await applyArchive(nextArchived);
      showToast({ message: nextArchived ? t('chat.archivedNotice') : t('chat.unarchivedNotice'), actionLabel: t('common.undo'), onAction: () => { void applyArchive(!nextArchived).catch(() => showToast({ message: t('chat.sendError') })); } });
    } catch { setError(t('chat.sendError')); }
  }
  async function blockCounterpart() {
    if (!transcript?.otherUserId) return;
    const targetId = transcript.otherUserId;
    try {
      await chatRepository.blockUser(targetId);
      setDetailsOpen(false);
      await navigate(path('messages'));
      showToast({ message: t('chat.blockedNotice'), actionLabel: t('common.undo'), onAction: () => { void api.patch(`/users/${encodeURIComponent(targetId)}/unblock`).catch(() => showToast({ message: t('chat.sendError') })); } });
    } catch { setError(t('chat.sendError')); }
  }
  async function openStarred() {
    try {
      const items = await chatRepository.starred(id);
      setStarred(items);
      setStarredIds(new Set(items.map((item) => item.id)));
      setDetailsOpen(false);
    } catch { setError(t('chat.loadError')); }
  }
  async function saveBackground() {
    if (background.startsWith('/media/background/') || /^data:image\/(?:png|jpeg|webp|gif);base64,[A-Za-z0-9+/=]+$/.test(background)) {
      try { await chatRepository.background(id, background); } catch { setError(t('chat.sendError')); }
    } else setError(t('chat.mediaError'));
  }
  async function runConfirmed() {
    const pendingConfirm = confirm;
    if (!pendingConfirm) return;
    setConfirm(null);
    if (pendingConfirm.kind === 'deleteConversation') {
      try { await chatRepository.deleteConversation(id); await navigate(path('messages')); } catch { setError(t('chat.sendError')); }
      return;
    }
    if (pendingConfirm.kind === 'deleteMessage' && pendingConfirm.messageId) {
      const messageId = pendingConfirm.messageId;
      try { await chatRepository.deleteMessage(id, messageId); setMessages((items) => items.map((item) => item.id === messageId ? deletedCopy(item) : item)); } catch { setError(t('chat.sendError')); }
      return;
    }
    if (pendingConfirm.kind === 'deleteSelected') { await deleteSelectedMessages(); return; }
    if (pendingConfirm.kind === 'block') { await blockCounterpart(); return; }
    if (pendingConfirm.kind === 'report' && transcript?.otherUserId) {
      try { await chatRepository.reportUser(transcript.otherUserId); } catch { setError(t('chat.sendError')); }
    }
  }
  function replyToSelected() {
    if (selectedIds.length !== 1) return;
    const target = messages.find((message) => message.id === selectedIds[0]);
    if (target) setReply(target);
    setSelectedIds([]);
  }
  function clearSelection() { setSelectedIds([]); setSelectedTargets([]); setForwardOpen(false); }
  async function setTheme(theme: string) {
    try {
      await chatRepository.theme(id, theme);
       setTranscript((current) => current ? { ...current, preference: { isArchived: current.preference?.isArchived ?? false, theme, backgroundUrl: current.preference?.backgroundUrl ?? null, muted: current.preference?.muted ?? false } } : current);
    } catch { setError(t('chat.sendError')); }
  }

  async function acceptConversation() { try { await chatRepository.accept(id); setConversation((current) => current ? { ...current, status: 'ACCEPTED' } : current); } catch { setError(t('chat.sendError')); } }
  async function loadGallery(type: MediaKind) {
    setGallery(type); setGalleryItems([]); setGalleryCursor(null); setPending(true);
    try { const page = await chatRepository.media(id, type); setGalleryItems(page.messages); setGalleryCursor(page.nextCursor); }
    catch { setError(t('chat.loadError')); }
    finally { setPending(false); }
  }
  async function forwardSelected() {
    if (!selectedTargets.length || !selectedIds.length) return;
    const selected = messages.filter((message) => selectedIds.includes(message.id));
    if (!canForwardSelection(selected.length, selected.some((message) => message.viewOnce), selected.some((message) => message.deletedAt !== null) || selected.length !== selectedIds.length)) {
      const key = selected.some((message) => message.viewOnce) ? 'chat.viewOnceForwardError' : selected.some((message) => message.deletedAt !== null) || selected.length !== selectedIds.length ? 'chat.deletedForwardError' : 'chat.forwardLimitError';
      setError(t(key)); return;
    }
    try {
      await chatRepository.forward(id, selectedIds, selectedTargets);
      setSelectedIds([]); setSelectedTargets([]);
    } catch { setError(t('chat.sendError')); }
  }
  async function loadMoreForwardTargets() {
    if (!forwardPage?.nextCursor) return;
    try { const next = await chatRepository.conversations({ q: forwardQuery, cursor: forwardPage.nextCursor }); setForwardPage((page) => page ? { ...next, items: [...page.items, ...next.items] } : next); }
    catch { setError(t('chat.loadError')); }
  }
  function toggleSelected(messageId: string, checked: boolean) {
    setSelectedIds((current) => checked ? [...new Set([...current, messageId])] : current.filter((item) => item !== messageId));
  }

  const status = transcript?.threadType === 'ORDER' ? t('chat.order') : conversation?.status === 'PENDING' ? t('chat.pending') : transcript ? t('chat.direct') : undefined;
  const locationPreview = locationMessageMetadata({ latitude: locationLatitude, longitude: locationLongitude, address: locationAddress, ...(locationAccuracy !== undefined ? { accuracyMeters: locationAccuracy } : {}), ...(locationCapturedAt ? { capturedAt: locationCapturedAt } : {}) });
  const locationMapUrl = locationPreview ? `https://www.google.com/maps/search/?api=1&query=${locationPreview.latitude},${locationPreview.longitude}` : null;
  const confirmMeta = confirm === null ? null
    : confirm.kind === 'deleteConversation' ? { title: t('chat.deleteConversation'), body: t('chat.confirmDeleteConversation'), actionLabel: t('common.delete'), danger: true }
    : confirm.kind === 'deleteMessage' ? { title: t('chat.deleteMessage'), body: t('chat.confirmDeleteMessage'), actionLabel: t('common.delete'), danger: true }
    : confirm.kind === 'deleteSelected' ? { title: t('chat.deleteSelected'), body: t('chat.confirmDeleteSelected'), actionLabel: t('common.delete'), danger: true }
    : confirm.kind === 'block' ? { title: t('chat.block'), body: t('chat.confirmBlock'), actionLabel: t('chat.block'), danger: true }
    : { title: t('chat.report'), body: t('chat.confirmReport'), actionLabel: t('chat.report'), danger: false };
  return <div className="mx-auto grid h-[100svh] max-w-7xl grid-cols-1 gap-3 px-3 py-3 text-ink sm:px-6 sm:py-6 md:grid-cols-[18rem_minmax(0,1fr)]">
    <div className="sr-only" aria-hidden>
      <div ref={threadLoadRef} />
      <div ref={inquiryRef} />
      <div ref={forwardRef} />
      <div ref={socketBindRef} />
      <div ref={backgroundRef} />
      <div ref={videoRef2} />
      <div ref={unmountRef} />
    </div>
    <aside className="hidden min-h-0 overflow-y-auto bg-surface p-3 md:block" aria-label={t('chat.title')}><h2 className="mb-3 font-display text-xl font-bold">{t('chat.title')}</h2><ul className="grid gap-1">{sidebarConversations.map((item) => <li key={`${item.threadType}:${item.id}`}><Link aria-current={item.id === id ? 'page' : undefined} className={`block p-3 ${item.id === id ? 'bg-surface-high' : 'hover:bg-surface-mid'}`} to={path(pathsFor.conversation(item.id))}><span className="block truncate font-semibold">{item.otherUser.displayName}</span><span className="block truncate text-xs text-muted">{item.product?.title ?? item.orderInfo?.productTitle ?? item.lastMessage?.content ?? item.status}</span></Link></li>)}</ul></aside>
    <section className="flex min-h-0 min-w-0 flex-col">
     <header className="flex shrink-0 flex-wrap items-center gap-2 bg-surface p-3 sm:p-4">
      <Link className="icon-control" to={path('messages')} aria-label={t('common.back')} title={t('common.back')}><Icon name="back" size={18} /></Link>
       <div className="min-w-0 flex-1"><h1 className="truncate font-display text-xl font-bold">{transcript?.otherUser.displayName ?? t('chat.thread')}</h1><p className="text-xs text-muted">{muted ? t('chat.muted') : presenceHidden ? t('chat.presenceHidden') : online ? t('chat.online') : typing ? t('chat.typing') : status}</p>{conversation?.product ? <Link className="text-xs text-brand underline" to={path(pathsFor.product(conversation.product.id))}>{conversation.product.title}</Link> : null}{conversation?.orderInfo ? <Link className="text-xs text-brand underline" to={path(pathsFor.order(conversation.orderInfo.id))}>{conversation.orderInfo.productTitle}</Link> : null}</div>
      <button className="icon-control" type="button" onClick={() => setDetailsOpen(true)} aria-label={t('chat.details')} title={t('chat.details')}><Icon name="info" size={18} /></button>
      <button className="icon-control" type="button" onClick={() => void loadGallery('IMAGE')} aria-label={t('chat.media')} title={t('chat.media')}><Icon name="image" size={18} /></button>
      <button className="icon-control" type="button" onClick={() => void openStarred()} aria-label={t('chat.starred')} title={t('chat.starred')}><Icon name="bookmark" size={18} /></button>
      <button className="icon-control" type="button" onClick={() => void setArchive()} aria-label={transcript?.preference?.isArchived ? t('chat.unarchive') : t('chat.archive')} title={transcript?.preference?.isArchived ? t('chat.unarchive') : t('chat.archive')}><Icon name="archive" size={18} /></button>
      <button className="icon-control icon-control-danger" type="button" onClick={() => setConfirm({ kind: 'deleteConversation' })} aria-label={t('chat.deleteConversation')} title={t('chat.deleteConversation')}><Icon name="trash" size={18} /></button>
    </header>
    {offline ? <p role="status" className="mt-2 bg-surface-mid p-2 text-sm">{t('chat.socketOffline')}</p> : null}
    {error ? <p role="alert" className="mt-2 bg-surface-high p-2 text-sm">{error}</p> : null}
    {conversation?.threadType === 'DIRECT' && conversation.status === 'PENDING' ? <button className="ui-button ui-primary mt-2" type="button" onClick={() => void acceptConversation()}>{t('chat.accept')}</button> : null}
    <section ref={scrollRef} aria-label={t('chat.thread')} className="mt-2 flex min-h-0 flex-1 flex-col gap-2 overflow-y-auto bg-canvas p-2 sm:p-4" style={backgroundImage ? { backgroundImage: `url("${backgroundImage}")`, backgroundSize: 'cover' } : undefined}>
      {transcript?.hasMore ? <button className="ui-button ui-secondary self-center" type="button" disabled={pending} onClick={() => void loadOlder()}>{t('chat.loadOlder')}</button> : null}
      {messages.map((message) => <article key={message.id} className={`chat-message max-w-[88%] bg-surface p-3 sm:max-w-[72%] ${message.senderId === session.user?.id ? 'self-end bg-surface-high' : 'self-start'}`} data-reactions={reactionsOpen === message.id ? 'open' : undefined}>
        {replyPreview(message, t('chat.media')) ? <blockquote className="mb-2 bg-surface-mid p-2 text-xs text-muted">{replyPreview(message, t('chat.media'))}</blockquote> : null}
        {message.deletedAt ? <p className="italic text-muted">{t('chat.deleteMessage')}</p> : message.viewOnce ? <AuthenticatedMedia src={message.attachmentUrl ?? ''} type={message.type === 'VIDEO' ? 'video' : message.type === 'AUDIO' ? 'audio' : 'image'} alt={t('chat.media')} conversationId={id} viewOnceMessage={message} /> : isMediaType(message.type) && message.attachmentUrl ? <AuthenticatedMedia src={message.attachmentUrl} type={message.type === 'VIDEO' ? 'video' : message.type === 'AUDIO' ? 'audio' : 'image'} alt={t('chat.media')} /> : message.type === 'LOCATION' && hasValidCoordinates(message.metadata?.latitude, message.metadata?.longitude) ? <button className="underline" type="button" onClick={() => void openExternal(`https://www.google.com/maps/search/?api=1&query=${message.metadata!.latitude},${message.metadata!.longitude}`)}>{t('chat.location')}{typeof message.metadata?.address === 'string' ? `: ${message.metadata.address}` : ''}</button> : message.type === 'PRODUCT_CARD' && typeof message.metadata?.productId === 'string' ? <Link className="grid gap-2 underline" to={path(pathsFor.product(message.metadata.productId))}><strong>{typeof message.metadata.title === 'string' ? message.metadata.title : t('chat.product')}</strong>{typeof message.metadata.price === 'number' ? <span>{new Intl.NumberFormat(locale, { style: 'currency', currency: 'BRL' }).format(message.metadata.price / 100)}</span> : null}</Link> : <p className="whitespace-pre-wrap break-words">{message.content}</p>}
        {message.content?.match(/https?:\/\/[^\s]+/g)?.map((url) => <button key={url} className="mt-2 block break-all text-brand underline" type="button" onClick={() => void openExternal(url)}>{t('chat.openLink')}: {url}</button>)}
        <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted">
          <time dateTime={message.createdAt}>{new Date(message.createdAt).toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })}</time>{message.senderId === session.user?.id && message.readAt ? <span aria-label={t('chat.read')}>{t('chat.read')}</span> : null}
          <button type="button" className="icon-control icon-control-sm" onClick={() => setReply(message)} aria-label={t('chat.reply')} title={t('chat.reply')}><Icon name="reply" size={15} /></button>
          <button type="button" className="icon-control icon-control-sm" aria-pressed={starredIds.has(message.id)} onClick={() => void toggleStar(message)} aria-label={starredIds.has(message.id) ? t('chat.unstar') : t('chat.star')} title={starredIds.has(message.id) ? t('chat.unstar') : t('chat.star')}><Icon name="bookmark" size={15} /></button>
          {message.senderId === session.user?.id && !message.deletedAt ? <button type="button" className="icon-control icon-control-sm" onClick={() => setConfirm({ kind: 'deleteMessage', messageId: message.id })} aria-label={t('chat.deleteMessage')} title={t('chat.deleteMessage')}><Icon name="trash" size={15} /></button> : null}
          <label className="ui-icon-toggle ui-icon-toggle-sm" title={`${t('chat.forward')} ${message.id}`}><input type="checkbox" aria-label={`${t('chat.forward')} ${message.id}`} checked={selectedIds.includes(message.id)} onChange={(event) => toggleSelected(message.id, event.currentTarget.checked)} /><Icon name="repeat" size={15} /></label>
          <button type="button" className="icon-control icon-control-sm" aria-expanded={reactionsOpen === message.id} onClick={() => setReactionsOpen((current) => current === message.id ? null : message.id)} aria-label={t('chat.reactions')} title={t('chat.reactions')}><Icon name="smile" size={15} /></button>
        </div>
        <div className="chat-reactions mt-1 flex-wrap gap-1" aria-label={t('chat.reactions')}>{CHAT_REACTIONS.map((emoji) => <button key={emoji} type="button" aria-label={`${t('chat.reactions')} ${emoji}`} className="min-h-8 min-w-8 bg-surface-mid" onClick={() => void toggleReaction(message, emoji)}>{emoji}{message.reactions?.find((item) => item.emoji === emoji)?.count ? ` ${message.reactions.find((item) => item.emoji === emoji)?.count}` : ''}</button>)}</div>
      </article>)}
      {!messages.length && !error ? <p className="m-auto text-muted">{t('chat.emptyThread')}</p> : null}
    </section>
    <form className="mt-2 grid shrink-0 gap-2 bg-surface p-3" onSubmit={submit}>
      {reply ? <div className="flex items-center justify-between bg-surface-mid p-2 text-sm"><span className="truncate">{t('chat.reply')}: {reply.content ?? t('chat.media')}</span><button type="button" className="underline" onClick={() => setReply(null)}>{t('chat.cancel')}</button></div> : null}
      {selectedIds.length ? <fieldset className="grid gap-2 bg-surface-mid p-2 text-sm"><legend>{t('chat.selected', { count: selectedIds.length })}</legend><div className="flex flex-wrap gap-2"><button type="button" className="icon-control icon-control-sm" onClick={() => void copySelected()} aria-label={t('chat.copy')} title={t('chat.copy')}><Icon name="doc" size={16} /></button><button type="button" className="icon-control icon-control-sm" onClick={() => void shareSelected()} aria-label={t('chat.share')} title={t('chat.share')}><Icon name="send" size={16} /></button><button type="button" className="icon-control icon-control-sm" onClick={() => void starSelected()} aria-label={t('chat.star')} title={t('chat.star')}><Icon name="bookmark" size={16} /></button><button type="button" className="icon-control icon-control-sm" onClick={() => setConfirm({ kind: 'deleteSelected' })} aria-label={t('chat.deleteSelected')} title={t('chat.deleteSelected')}><Icon name="trash" size={16} /></button><button type="button" className="icon-control icon-control-sm" onClick={replyToSelected} aria-label={t('chat.reply')} title={t('chat.reply')}><Icon name="reply" size={16} /></button></div><button className="icon-control icon-control-sm justify-self-start" type="button" onClick={() => setForwardOpen((open) => !open)} aria-label={t('chat.chooseRecipients')} title={t('chat.chooseRecipients')}><Icon name="chevronRight" size={16} /></button>{forwardOpen ? <><input aria-label={t('chat.searchConversations')} className="min-h-10 bg-surface-high p-2" type="search" value={forwardQuery} onChange={(event) => setForwardQuery(event.currentTarget.value)} />{forwardPage?.items.map((item) => <label key={item.id} className="flex items-center gap-1"><input type="checkbox" checked={selectedTargets.includes(item.id)} onChange={(event) => { const checked = event.currentTarget.checked; setSelectedTargets((targets) => checked ? [...new Set([...targets, item.id])] : targets.filter((target) => target !== item.id)); }} />{item.otherUser.displayName} {item.product?.title ?? item.orderInfo?.productTitle ?? ''}</label>)}{forwardPage?.nextCursor ? <button type="button" className="underline" onClick={() => void loadMoreForwardTargets()}>{t('common.loadMore')}</button> : null}</> : null}<div className="flex flex-wrap gap-2"><button className="icon-control icon-control-sm" type="button" disabled={!selectedTargets.length} onClick={() => void forwardSelected()} aria-label={t('chat.forward')} title={t('chat.forward')}><Icon name="repeat" size={16} /></button><button className="icon-control icon-control-sm" type="button" onClick={clearSelection} aria-label={t('chat.cancel')} title={t('chat.cancel')}><Icon name="close" size={16} /></button></div></fieldset> : null}
      <ChatComposer ref={inputRef} label={t('chat.message')} value={draft} disabled={pending} maxLength={5000} onChange={handleDraftChange} onSend={sendDraft} />
      <div className="chat-composer-actions">
        <label className="icon-control cursor-pointer" aria-label={t('chat.upload')} title={t('chat.upload')}><Icon name="attach" size={18} /><input className="sr-only" type="file" accept="image/*,video/*,audio/*" disabled={pending} aria-label={t('chat.upload')} onChange={(event) => { const file = event.currentTarget.files?.[0]; if (file?.type.startsWith('image/')) { setImageToEdit(file); setImageEdited(false); setImageCaption(''); } else if (file?.type.startsWith('video/')) { setVideoToSend(file); setVideoCaption(''); setVideoViewOnce(viewOnce); } else if (file) void upload(file); event.currentTarget.value = ''; }} /></label>
        <label className="ui-icon-toggle" title={t('chat.viewOnce')} aria-label={t('chat.viewOnce')}><input type="checkbox" checked={viewOnce} onChange={(event) => setViewOnce(event.currentTarget.checked)} aria-label={t('chat.viewOnce')} /><Icon name="viewOnce" size={18} /></label>
        <button className="icon-control" type="button" onClick={() => void shareLocation()} aria-label={t('chat.location')} title={t('chat.location')}><Icon name="pin" size={18} /></button>
        <button className="icon-control" type="button" onClick={() => void openProductPicker()} aria-label={t('chat.shareProduct')} title={t('chat.shareProduct')}><Icon name="sell" size={18} /></button>
        {!recording ? <button className="icon-control" type="button" onClick={() => void startRecording()} aria-label={t('chat.record')} title={t('chat.record')}><Icon name="mic" size={18} /></button> : <><button className="icon-control icon-control-danger" type="button" onClick={() => recorderRef.current?.stop()} aria-label={t('chat.send')} title={t('chat.send')}><Icon name="stop" size={18} /></button><button className="icon-control" type="button" onClick={() => { cancelRecording.current = true; recorderRef.current?.stop(); }} aria-label={t('chat.cancel')} title={t('chat.cancel')}><Icon name="close" size={18} /></button></>}
        <button className="icon-control icon-control-primary ml-auto" type="submit" disabled={pending || !draft.trim()} aria-label={t('chat.send')} title={t('chat.send')}><Icon name="send" size={18} /></button>
      </div>
      {recordUnsupported ? <p role="status" className="text-xs text-muted">{t('chat.recordUnsupported')}</p> : null}
    </form>
    </section>
    <Dialog open={Boolean(gallery)} onClose={() => setGallery(null)} title={t('chat.media')}>
      <nav className="my-3 flex flex-wrap gap-2">{(['IMAGE', 'VIDEO', 'AUDIO'] as const).map((type) => <button key={type} className="ui-button ui-secondary" onClick={() => void loadGallery(type)}>{type === 'IMAGE' ? t('chat.mediaImage') : type === 'VIDEO' ? t('chat.mediaVideo') : t('chat.mediaAudio')}</button>)}</nav>
      <div className="grid max-h-[65svh] gap-3 overflow-auto">{galleryItems.map((message) => message.attachmentUrl && isMediaType(message.type) ? <AuthenticatedMedia key={message.id} src={message.attachmentUrl} type={message.type === 'VIDEO' ? 'video' : message.type === 'AUDIO' ? 'audio' : 'image'} alt={t('chat.media')} /> : null)}</div>
      {galleryCursor ? <button className="ui-button ui-secondary mt-3" onClick={() => void loadOlderMedia()}>{t('common.loadMore')}</button> : null}
    </Dialog>
    <Dialog open={starred !== null} onClose={() => setStarred(null)} title={t('chat.starred')}>
      {starred?.length ? starred.map((message) => <p key={message.id} className="my-2 bg-surface-mid p-3">{message.content ?? t('chat.media')}</p>) : <p>{t('chat.starredEmpty')}</p>}
    </Dialog>
    <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} title={t('chat.details')}>
      <div className="chat-details-actions">
        {transcript?.otherUserId ? <Link className="icon-control" to={path(pathsFor.person(transcript.otherUserId))} aria-label={`${t('chat.profile')}: ${transcript.otherUser.displayName}`} title={`${t('chat.profile')}: ${transcript.otherUser.displayName}`}><Icon name="user" size={18} /></Link> : null}
        <button type="button" className="icon-control" aria-pressed={muted} onClick={toggleMute} aria-label={muted ? t('chat.unmute') : t('chat.mute')} title={muted ? t('chat.unmute') : t('chat.mute')}><Icon name={muted ? 'volumeOn' : 'volumeOff'} size={18} /></button>
        <button type="button" className="icon-control" aria-pressed={presenceHidden} onClick={togglePresenceHidden} aria-label={presenceHidden ? t('chat.showPresence') : t('chat.hidePresence')} title={presenceHidden ? t('chat.showPresence') : t('chat.hidePresence')}><Icon name={presenceHidden ? 'eye' : 'eyeOff'} size={18} /></button>
        <button type="button" className="icon-control" onClick={() => { setDetailsOpen(false); void loadGallery('IMAGE'); }} aria-label={t('chat.media')} title={t('chat.media')}><Icon name="image" size={18} /></button>
        <button type="button" className="icon-control" onClick={() => void openStarred()} aria-label={t('chat.starred')} title={t('chat.starred')}><Icon name="bookmark" size={18} /></button>
        {transcript?.otherUserId ? <button type="button" className="icon-control icon-control-danger" onClick={() => setConfirm({ kind: 'block' })} aria-label={t('chat.block')} title={t('chat.block')}><Icon name="shield" size={18} /></button> : null}
        {transcript?.otherUserId ? <button type="button" className="icon-control" onClick={() => { setDetailsOpen(false); setConfirm({ kind: 'report' }); }} aria-label={t('chat.report')} title={t('chat.report')}><Icon name="doc" size={18} /></button> : null}
      </div>
      <Select label={t('chat.theme')} value={transcript?.preference?.theme ?? 'DEFAULT'} onChange={(event) => void setTheme(event.currentTarget.value)}>{CHAT_THEMES.map((theme) => <option key={theme} value={theme}>{t(`chat.theme.${theme}`)}</option>)}</Select>
      <div className="chat-details-row">
        <label className="icon-control cursor-pointer" aria-label={t('chat.uploadBackground')} title={t('chat.uploadBackground')}><Icon name="image" size={18} /><input className="sr-only" type="file" accept="image/png,image/jpeg,image/webp,image/gif" aria-label={t('chat.uploadBackground')} onChange={(event) => { const file = event.currentTarget.files?.[0]; if (file) void uploadBackground(file); event.currentTarget.value = ''; }} /></label>
        <input aria-label={t('chat.background')} className="min-w-0 flex-1 bg-surface-high p-2" value={background} onChange={(event) => setBackground(event.currentTarget.value)} />
        <button className="icon-control" type="button" onClick={() => void saveBackground()} aria-label={t('chat.saveBackground')} title={t('chat.saveBackground')}><Icon name="check" size={18} /></button>
      </div>
    </Dialog>
    <Dialog open={confirm !== null} onClose={() => setConfirm(null)} title={confirmMeta?.title ?? t('common.confirm')} actions={confirmMeta ? <><Button variant="secondary" onClick={() => setConfirm(null)}>{t('common.cancel')}</Button><Button variant={confirmMeta.danger ? 'danger' : 'primary'} onClick={() => void runConfirmed()}>{confirmMeta.actionLabel}</Button></> : undefined}>{confirmMeta?.body}</Dialog>
    <Dialog open={imageToEdit !== null} onClose={() => setImageToEdit(null)} title={t('chat.editImage')}>
      {imageToEdit && !imageEdited ? <ImageEditor file={imageToEdit} onCancel={() => setImageToEdit(null)} onSave={(file) => { setImageToEdit(file); setImageEdited(true); }} /> : null}
      {imageToEdit && imageEdited ? <><label className="ui-field">{t('chat.caption')}<textarea className="min-h-20" maxLength={5000} value={imageCaption} onChange={(event) => setImageCaption(event.currentTarget.value)} /></label><button type="button" className="ui-button ui-primary mt-3" disabled={pending} onClick={() => { const file = imageToEdit; setImageToEdit(null); void upload(file, undefined, imageCaption); }}>{t('chat.send')}</button></> : null}
    </Dialog>
    <Dialog open={productsOpen} onClose={() => setProductsOpen(false)} title={t('chat.shareProduct')}>
      <input className="min-h-10 w-full bg-surface-high p-2" aria-label={t('chat.searchProducts')} value={productQuery} onChange={(event) => setProductQuery(event.currentTarget.value)} type="search" />
      {products.filter((product) => product.title.toLocaleLowerCase().includes(productQuery.toLocaleLowerCase())).map((product) => <button key={product.id} type="button" className="block w-full bg-surface-mid p-3 text-left" onClick={() => void sendProductCard(product)}>{product.title}</button>)}
      {!products.length ? <p role="status">{t('chat.noProducts')}</p> : null}
    </Dialog>
    <Dialog open={videoToSend !== null} onClose={() => setVideoToSend(null)} title={t('chat.videoPreview')}>
      {videoUrl ? <video className="max-h-96 max-w-full" src={videoUrl} controls muted playsInline /> : null}
      <label className="ui-field mt-3">{t('chat.caption')}<textarea className="min-h-20" maxLength={5000} value={videoCaption} onChange={(event) => setVideoCaption(event.currentTarget.value)} /></label>
      <label className="mt-2 flex items-center gap-2"><input type="checkbox" checked={videoViewOnce} onChange={(event) => setVideoViewOnce(event.currentTarget.checked)} />{t('chat.viewOnce')}</label>
       <button className="ui-button ui-primary mt-3" type="button" disabled={pending || !videoToSend} onClick={() => { if (!videoToSend) return; const file = videoToSend; setVideoToSend(null); void upload(file, undefined, videoCaption, videoViewOnce); }}>{t('chat.send')}</button>
    </Dialog>
    <Dialog open={locationOpen} onClose={() => setLocationOpen(false)} title={t('chat.location')}>
       <p className="mb-3 text-sm text-muted">{t('chat.locationMeasuredHint')}</p>
       <label className="grid gap-1">{t('chat.latitude')}<input className="min-h-11 bg-surface-high p-2" type="text" value={locationLatitude} readOnly /></label>
       <label className="mt-2 grid gap-1">{t('chat.longitude')}<input className="min-h-11 bg-surface-high p-2" type="text" value={locationLongitude} readOnly /></label>
       {locationAccuracy !== undefined && locationCapturedAt ? <p role="status" className="mt-2 text-sm text-muted">{t('chat.locationMeasurement', { accuracy: locationAccuracy, capturedAt: new Date(locationCapturedAt).toLocaleString(locale) })}</p> : null}
      <label className="mt-2 grid gap-1">{t('chat.placeName')}<input className="min-h-11 bg-surface-high p-2" type="text" maxLength={500} value={locationAddress} onChange={(event) => { setLocationAddress(event.currentTarget.value); setLocationError(''); }} /></label>
      <div className="mt-3 flex flex-wrap gap-2"><button type="button" className="ui-button ui-secondary" onClick={useCurrentLocation}>{t('chat.useCurrentLocation')}</button>{locationMapUrl ? <button type="button" className="ui-button ui-ghost" onClick={() => void openExternal(locationMapUrl)}>{t('chat.previewMap')}</button> : null}</div>
      {locationError ? <p role="alert" className="mt-2 text-danger">{locationError}</p> : null}
      <button type="button" className="ui-button ui-primary mt-3" disabled={!locationPreview || pending} onClick={sendChosenLocation}>{t('chat.sendLocation')}</button>
    </Dialog>
  </div>;
}
export default function ChatThreadPage() { return <RequireAuth><Thread /></RequireAuth>; }
