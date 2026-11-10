import { useRef, useState, type FormEvent } from 'react';
import { ComposerInput } from '../../../components';
import { useI18n } from '../../../core/locale';
import { chatCatalogs } from '../catalogs';
import { CHAT_REACTIONS, type ChatMessage } from '../model';
import { useAudioRecorder } from '../hooks/use-audio-recorder';
import { chatRepository } from '../repository';
import { ImageAttachmentDialog } from './image-attachment-dialog';
import { LocationDialog } from './location-dialog';
import { ProductPickerDialog, type ProductCard } from './product-picker-dialog';
import { useMessageSend } from './use-message-send';
import { VideoAttachmentDialog } from './video-attachment-dialog';
import { ComposerControls } from './composer-controls';

type ComposerProps = {
  conversationId: string;
  locale: string;
  inquiry: { ready: boolean; productId?: string; otherUserId?: string };
  reply: ChatMessage | null;
  onReplyChange: (message: ChatMessage | null) => void;
  typing: { emitDraftActivity: (value: string) => void; emitStopTyping: () => void };
  reaction?: { message: ChatMessage; onSelect: (emoji: string) => void };
  onError: (message: string) => void;
  onSendingChange: (sending: boolean) => void;
};

export function ThreadComposer(props: ComposerProps) {
  const { t } = useI18n(chatCatalogs);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [locationOpen, setLocationOpen] = useState(false);
  const [products, setProducts] = useState<ProductCard[] | null>(null);
  const inputRef = useRef<HTMLTextAreaElement>(null);
  const sender = useMessageSend({ ...props, inputRef });
  const recorder = useAudioRecorder((file, durationMs) => void sender.upload(file, durationMs));

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    sender.sendDraft();
  }

  function pickEmoji(emoji: string) {
    if (props.reaction) {
      props.reaction.onSelect(emoji);
      return;
    }
    const field = inputRef.current;
    if (!field) return;
    field.setRangeText(emoji, field.selectionStart, field.selectionEnd, 'end');
    sender.changeDraft(field.value);
  }

  async function loadProducts() {
    try {
      setProducts((await chatRepository.myProducts()).products);
    } catch {
      props.onError(t('chat.loadError'));
    }
  }

  async function sendProduct(product: ProductCard) {
    try {
      await sender.sendAsync({
        type: 'PRODUCT_CARD',
        clientMessageId: crypto.randomUUID(),
        metadata: {
          productId: product.id,
          title: product.title,
          price: product.price,
          imageUrl: product.imageUrl,
        },
      });
      setProducts(null);
    } catch {
      props.onError(t('chat.sendError'));
    }
  }

  return (
    <>
      <form className="mt-2 grid shrink-0 gap-2 surface p-3" onSubmit={submit}>
        {props.reply ? (
          <div className="flex items-center justify-between bg-surface-mid p-2 text-sm">
            <span className="truncate">
              {t('chat.reply')}: {props.reply.content ?? t('chat.media')}
            </span>
            <button type="button" className="underline" onClick={() => props.onReplyChange(null)}>
              {t('chat.cancel')}
            </button>
          </div>
        ) : null}
        <div className="emoji-wrap">
          <ComposerInput
            ref={inputRef}
            label={t('chat.message')}
            placeholder={t('chat.composerPlaceholder')}
            value={sender.draft}
            disabled={sender.pending}
            maxLength={5000}
            onChange={sender.changeDraft}
            onSubmit={sender.sendDraft}
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
        <ComposerControls
          sender={sender}
          recorder={recorder}
          onImage={setImageFile}
          onVideo={setVideoFile}
          onLocation={() => setLocationOpen(true)}
          onProducts={() => void loadProducts()}
        />
      </form>
      {imageFile ? (
        <ImageAttachmentDialog
          file={imageFile}
          pending={sender.pending}
          onClose={() => setImageFile(null)}
          onSend={(file, caption) => {
            setImageFile(null);
            void sender.upload(file, undefined, caption);
          }}
        />
      ) : null}
      {videoFile ? (
        <VideoAttachmentDialog
          file={videoFile}
          initialViewOnce={sender.viewOnce}
          pending={sender.pending}
          onClose={() => setVideoFile(null)}
          onSend={(file, caption, viewOnce) => {
            setVideoFile(null);
            void sender.upload(file, undefined, caption, viewOnce);
          }}
        />
      ) : null}
      {locationOpen ? (
        <LocationDialog
          locale={props.locale}
          pending={sender.pending}
          onClose={() => setLocationOpen(false)}
          onSend={(metadata) => {
            setLocationOpen(false);
            void sender.sendAsync({
              type: 'LOCATION',
              clientMessageId: crypto.randomUUID(),
              metadata,
            });
          }}
        />
      ) : null}
      {products ? (
        <ProductPickerDialog
          products={products}
          onClose={() => setProducts(null)}
          onSend={(product) => void sendProduct(product)}
        />
      ) : null}
    </>
  );
}
