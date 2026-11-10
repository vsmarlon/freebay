import { filters } from './constants';
import type { EditorState } from './use-editor';

export function EditorToolbar({
  editor,
  locale,
  label,
}: {
  editor: EditorState;
  locale: 'en' | 'pt-BR';
  label: readonly string[];
}) {
  const { tool } = editor;
  return (
    <div className="flex flex-wrap gap-2 [&>label]:flex [&>label]:items-center [&>label]:gap-1.5 [&_select]:min-h-10 [&_select]:border [&_select]:border-ink [&_select]:bg-surface [&_select]:p-1.5 [&_select]:text-ink">
      <button type="button" onClick={editor.applyCrop} disabled={!editor.selection}>
        {label[0]}
      </button>
      <button type="button" onClick={() => editor.setAngle((value) => value - 90)}>
        {label[1]}
      </button>
      <button type="button" onClick={() => editor.setAngle((value) => value + 90)}>
        {label[2]}
      </button>
      <label>
        {label[3]}{' '}
        <select
          aria-label={label[3]}
          value={editor.filter}
          onChange={(event) => editor.setFilter(Number(event.currentTarget.value))}
        >
          {filters.map((_, index) => (
            <option key={index} value={index}>
              {
                (locale === 'en'
                  ? ['Normal', 'Clarendon', 'Gingham', 'Moon', 'Lark', 'Reyes', 'Juno']
                  : ['Normal', 'Clarendon', 'Gingham', 'Lua', 'Lark', 'Reyes', 'Juno'])[index]
              }
            </option>
          ))}
        </select>
      </label>
      <label>
        {locale === 'en' ? 'Brightness' : 'Brilho'}
        <input
          aria-label={locale === 'en' ? 'Brightness' : 'Brilho'}
          type="range"
          min="0"
          max="2"
          step=".05"
          value={editor.brightness}
          onChange={(event) => editor.setBrightness(Number(event.currentTarget.value))}
        />
      </label>
      <label>
        {locale === 'en' ? 'Contrast' : 'Contraste'}
        <input
          aria-label={locale === 'en' ? 'Contrast' : 'Contraste'}
          type="range"
          min="0"
          max="2"
          step=".05"
          value={editor.contrast}
          onChange={(event) => editor.setContrast(Number(event.currentTarget.value))}
        />
      </label>
      <label>
        {locale === 'en' ? 'Saturation' : 'Saturação'}
        <input
          aria-label={locale === 'en' ? 'Saturation' : 'Saturação'}
          type="range"
          min="0"
          max="2"
          step=".05"
          value={editor.saturation}
          onChange={(event) => editor.setSaturation(Number(event.currentTarget.value))}
        />
      </label>
      <label>
        {locale === 'en' ? 'Rotation' : 'Rotação'}
        <input
          aria-label={locale === 'en' ? 'Rotation' : 'Rotação'}
          type="range"
          min="-180"
          max="180"
          step="1"
          value={((((editor.angle + 180) % 360) + 360) % 360) - 180}
          onChange={(event) => editor.setAngle(Number(event.currentTarget.value))}
        />
      </label>
      <button
        type="button"
        onClick={() => {
          const value = window.prompt(
            label[8],
            editor.text || (locale === 'en' ? 'NEW TEXT' : 'NOVO TEXTO'),
          );
          if (value !== null) {
            editor.setText(value.slice(0, 2000));
            editor.setOverlay(value.slice(0, 2000));
          }
        }}
      >
        {label[4]}
      </button>
      <button
        type="button"
        aria-pressed={tool === 'draw'}
        onClick={() => editor.setTool(tool === 'draw' ? 'crop' : 'draw')}
      >
        {label[5]}
      </button>
      {tool === 'draw' && (
        <>
          <label>
            {locale === 'en' ? 'Draw color' : 'Cor do traço'}
            <input
              aria-label={locale === 'en' ? 'Draw color' : 'Cor do traço'}
              type="color"
              value={editor.drawColor}
              onChange={(event) => editor.setDrawColor(event.currentTarget.value)}
            />
          </label>
          <label>
            {locale === 'en' ? 'Pen style' : 'Estilo do traço'}
            <select
              aria-label={locale === 'en' ? 'Pen style' : 'Estilo do traço'}
              value={editor.penStyle}
              onChange={(event) =>
                editor.setPenStyle(event.currentTarget.value as EditorState['penStyle'])
              }
            >
              <option value="marker">{locale === 'en' ? 'Marker' : 'Marcador'}</option>
              <option value="highlighter">{locale === 'en' ? 'Highlighter' : 'Marca-texto'}</option>
              <option value="eraser">{locale === 'en' ? 'Eraser' : 'Borracha'}</option>
            </select>
          </label>
          <label>
            {locale === 'en' ? 'Draw width' : 'Espessura'}
            <input
              aria-label={locale === 'en' ? 'Draw width' : 'Espessura'}
              type="range"
              min="2"
              max="24"
              value={editor.drawWidth}
              onChange={(event) => editor.setDrawWidth(Number(event.currentTarget.value))}
            />
          </label>
          <button
            type="button"
            disabled={!editor.strokes.length}
            onClick={() => editor.setStrokes((current) => current.slice(0, -1))}
          >
            {locale === 'en' ? 'Undo' : 'Desfazer'}
          </button>
          <button
            type="button"
            disabled={!editor.strokes.length}
            onClick={() => editor.setStrokes([])}
          >
            {locale === 'en' ? 'Clear' : 'Limpar'}
          </button>
        </>
      )}
    </div>
  );
}
