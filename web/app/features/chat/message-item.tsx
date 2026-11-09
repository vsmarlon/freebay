import { Link } from 'react-router';
import { Avatar, Icon } from '../../components/index';
import { VoicePlayer } from '../../components/voice-player';
import { useI18n } from '../../core/locale';
import { pathsFor } from '../../core/routes';
import en from './catalogs/en.json';
import ptBR from './catalogs/pt-BR.json';
import { hasValidCoordinates, replyPreview, type ChatMessage, type MediaKind } from './model';
import { AuthenticatedMedia } from './media';

const catalogs = { en, 'pt-BR': ptBR };
const isMediaType = (type: string): type is MediaKind => type === 'IMAGE' || type === 'VIDEO' || type === 'AUDIO';

type MessageItemProps = {
  message: ChatMessage;
  conversationId: string;
  locale: string;
  userId: string | undefined;
  userAvatar: string | null;
  userName: string;
  otherName: string;
  otherAvatar: string | null;
  selected: boolean;
  onToggle: (messageId: string, selected: boolean) => void;
  onReply: (message: ChatMessage) => void;
  onOpenExternal: (url: string) => void;
};

export function MessageItem({ message, conversationId, locale, userId, userAvatar, userName, otherName, otherAvatar, selected, onToggle, onReply, onOpenExternal }: MessageItemProps) {
  const { t, path } = useI18n(catalogs);
  const own = message.senderId === userId;
  return <article onClick={(event) => { if (message.deletedAt) return; if ((event.target as HTMLElement).closest('button, a, input, label, [data-auth-media], .voice-player, video, audio, img')) return; onToggle(message.id, !selected); }} className={`relative min-w-0 max-w-[88%] cursor-pointer border border-(--hairline) bg-surface p-3 sm:max-w-[72%] ${own ? 'self-end bg-surface-high border-[color-mix(in_srgb,var(--brand)_45%,var(--hairline))]' : 'self-start'} ${selected ? 'outline-2 outline-offset-2 outline-brand' : ''}`} data-own={own ? 'true' : 'false'} data-selected={selected ? 'true' : 'false'}>
    <div className={`mb-1.5 flex items-center gap-1.5 text-[11px] font-semibold text-muted ${own ? 'justify-end' : ''}`}><Avatar src={own ? userAvatar : otherAvatar} name={own ? userName : otherName} size={22} /><span>{own ? t('chat.you') : otherName}</span></div>
    {selected ? <button type="button" className={`icon-control absolute top-2.5 ${own ? 'right-[-28px]' : 'left-[-28px]'}`} aria-label={t('chat.reply')} title={t('chat.reply')} onClick={() => onReply(message)}><Icon name="reply" size={16} /></button> : null}
    {replyPreview(message, t('chat.media')) ? <blockquote className="mb-2 bg-surface-mid p-2 text-xs text-muted">{replyPreview(message, t('chat.media'))}</blockquote> : null}
    {message.deletedAt ? <p className="italic text-muted">{t('chat.deleteMessage')}</p> : message.viewOnce ? <span data-auth-media="" onClick={(event) => event.stopPropagation()} style={{ display: 'contents' }}><AuthenticatedMedia src={message.attachmentUrl ?? ''} type={message.type === 'VIDEO' ? 'video' : message.type === 'AUDIO' ? 'audio' : 'image'} alt={t('chat.media')} conversationId={conversationId} viewOnceMessageId={message.id} viewOnceSenderId={message.senderId} /></span> : isMediaType(message.type) && message.attachmentUrl ? (message.type === 'AUDIO' ? <VoicePlayer src={message.attachmentUrl} playLabel={t('chat.play')} pauseLabel={t('chat.pause')} seekLabel={t('chat.seek')} fallbackLabel={t('chat.mediaError')} /> : <span data-auth-media="" onClick={(event) => event.stopPropagation()} style={{ display: 'contents' }}><AuthenticatedMedia src={message.attachmentUrl} type={message.type === 'VIDEO' ? 'video' : 'image'} alt={t('chat.media')} /></span>) : message.type === 'LOCATION' && hasValidCoordinates(message.metadata?.latitude, message.metadata?.longitude) ? <button className="underline" type="button" onClick={() => onOpenExternal(`https://www.google.com/maps/search/?api=1&query=${message.metadata!.latitude},${message.metadata!.longitude}`)}>{t('chat.location')}{typeof message.metadata?.address === 'string' ? `: ${message.metadata.address}` : ''}</button> : message.type === 'PRODUCT_CARD' && typeof message.metadata?.productId === 'string' ? <Link className="grid gap-2 underline" to={path(pathsFor.product(message.metadata.productId))}><strong>{typeof message.metadata.title === 'string' ? message.metadata.title : t('chat.product')}</strong>{typeof message.metadata.price === 'number' ? <span>{new Intl.NumberFormat(locale, { style: 'currency', currency: 'BRL' }).format(message.metadata.price / 100)}</span> : null}</Link> : <p className="whitespace-pre-wrap wrap-break-word">{message.content}</p>}
    {message.content?.match(/https?:\/\/[^\s]+/g)?.map((url) => <button key={url} className="mt-2 block break-all text-brand underline" type="button" onClick={() => onOpenExternal(url)}>{t('chat.openLink')}: {url}</button>)}
    {message.type === 'LOCATION' && !message.deletedAt ? <p className="text-xs text-muted">{t('chat.meetupNote')}</p> : null}
    <div className="mt-2 flex flex-wrap items-center gap-2 text-xs text-muted">
      <time dateTime={message.createdAt}>{new Date(message.createdAt).toLocaleTimeString(locale, { hour: '2-digit', minute: '2-digit' })}</time>{own && message.readAt ? <span aria-label={t('chat.read')}>{t('chat.read')}</span> : null}
    </div>
    {message.reactions?.length ? <div className="absolute bottom-[-13px] right-2.5 z-1 flex gap-0.5" aria-label={t('chat.reactions')}>{message.reactions.map((item) => <span key={item.emoji} className="inline-flex items-center gap-1 border border-(--hairline) bg-surface px-2 py-0.5 text-[11px] text-ink shadow-[2px_2px_#0003]">{item.emoji}{item.count ? ` ${item.count}` : ''}</span>)}</div> : null}
  </article>;
}
