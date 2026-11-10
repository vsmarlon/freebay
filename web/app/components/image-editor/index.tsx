import { useLocation } from 'react-router';
import { names } from './constants';
import { EditorToolbar } from './editor-toolbar';
import { useEditor } from './use-editor';
import { useImageSource } from './use-image-source';

type ImageEditorProps = { file: File; onSave: (file: File) => void; onCancel: () => void };

export function ImageEditor({ file, onSave, onCancel }: ImageEditorProps) {
  const location = useLocation();
  const locale = location.pathname.split('/')[1] === 'en' ? 'en' : 'pt-BR';
  const label = names[locale];
  const { loaded, image, setImage, size, setSize, sourceRef } = useImageSource(file);
  const editor = useEditor({ file, image, setImage, size, setSize, label, onSave });
  const { error, redraw, moveCropWithKeyboard, pointerDown, pointerMove, pointerUp, save } = editor;

  return (
    <section
      className="grid max-w-full gap-3 p-4"
      aria-label={locale === 'en' ? 'Image editor' : 'Editor de imagem'}
    >
      <div ref={sourceRef} hidden />
      {loaded === null ? null : 'error' in loaded ? (
        <p role="alert">{label[9]}</p>
      ) : (
        <>
          <EditorToolbar editor={editor} locale={locale} label={label} />
          <p id="image-editor-hint" className="text-muted">
            {label[10]}
          </p>
          <canvas
            className="m-auto block max-h-[60svh] max-w-full touch-none object-contain"
            ref={redraw}
            tabIndex={0}
            aria-label={label[0]}
            aria-describedby="image-editor-hint"
            onKeyDown={moveCropWithKeyboard}
            onPointerDown={pointerDown}
            onPointerMove={pointerMove}
            onPointerUp={pointerUp}
            onPointerCancel={pointerUp}
          />
          {error && <p role="alert">{error}</p>}
          <footer className="flex justify-end gap-2.5">
            <button
              type="button"
              className="min-h-10 border border-ink bg-surface px-3 text-ink"
              onClick={onCancel}
            >
              {label[7]}
            </button>
            <button
              type="button"
              className="min-h-10 border border-ink bg-brand px-3.5 font-display text-[13px] font-bold text-white disabled:cursor-not-allowed disabled:opacity-50"
              onClick={() => void save()}
              disabled={Boolean(error) || !image}
            >
              {label[6]}
            </button>
          </footer>
        </>
      )}
    </section>
  );
}

export {
  boundedImageSize,
  editedImageFile,
  rotatedImageSize,
  supportedEditorFile,
} from './geometry';
