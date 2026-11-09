import { useState } from 'react';
import { Link, useNavigate } from 'react-router';
import { storiesApi } from './api';
import { paths } from '../../core/routes';
import { RequireAuth } from '../../core/session';
import { ImageEditor } from '../../components/image-editor';
import { VideoEditor } from '../../components/video-editor';
import { Button, FilePicker, Select, TextArea } from '../../components';
import {
  serializeStoryTextBlocks,
  StoryTextBlockEditor,
  type StoryTextBlock,
} from './text-block-editor';
import { useStoryCopy } from './shared';

export function CreateStory() {
  const { path, t } = useStoryCopy();
  const navigate = useNavigate();
  const [file, setFile] = useState<File>();
  const [editingFile, setEditingFile] = useState<File>();
  const [editingVideo, setEditingVideo] = useState<File>();
  const [caption, setCaption] = useState('');
  const [audience, setAudience] = useState<'EVERYONE' | 'CLOSE_FRIENDS'>('EVERYONE');
  const [blocks, setBlocks] = useState<StoryTextBlock[]>([]);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState('');
  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!file) {
      setError(t.fileRequired);
      return;
    }
    const video = file.type.startsWith('video/');
    const allowed = video
      ? ['video/mp4', 'video/quicktime', 'video/webm']
      : ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (!allowed.includes(file.type)) {
      setError(t.unsupported);
      return;
    }
    if (
      file.size > (video ? 25 : 5) * 1024 * 1024 ||
      caption.length > 500 ||
      blocks.length > 10 ||
      blocks.some((block) => !block.text.trim() || block.text.length > 200)
    ) {
      setError(t.submitError);
      return;
    }
    const form = new FormData();
    form.append('image', file);
    form.append('audience', audience);
    form.append('caption', caption);
    form.append('textBlocks', serializeStoryTextBlocks(blocks));
    setPending(true);
    setError('');
    try {
      await storiesApi.create(form);
      navigate(path(paths.feed), { replace: true });
    } catch {
      setError(t.submitError);
    } finally {
      setPending(false);
    }
  };
  return (
    <div className="mx-auto min-h-screen max-w-xl p-6 text-ink">
      <Link to={path(paths.feed)}>{t.cancel}</Link>
      <h1 className="my-6 font-display text-3xl font-bold">{t.create}</h1>
      <form className="space-y-5" onSubmit={(event) => void submit(event)}>
        <FilePicker
          label={t.file}
          buttonLabel={t.choose}
          accept="image/jpeg,image/png,image/webp,image/gif,video/mp4,video/quicktime,video/webm"
          capture="environment"
          fileName={file?.name}
          onChange={(selected) => {
            setFile(undefined);
            setBlocks([]);
            if (!selected) return;
            if (selected.type.startsWith('video/')) setEditingVideo(selected);
            else setEditingFile(selected);
          }}
        />
        <p className="text-sm text-ink-muted">{t.uploadLimit}</p>
        {/* live story preview: media + text overlays + caption, composed like the viewer renders it */}
        {file ? (
          <StoryTextBlockEditor
            file={file}
            caption={caption}
            blocks={blocks}
            onChange={setBlocks}
            copy={{
              addText: t.addText,
              removeText: t.removeText,
              text: t.text,
              style: t.textStyle,
              color: t.textColor,
              positionX: t.positionX,
              positionY: t.positionY,
              size: t.textSize,
              rotation: t.textRotation,
              layer: t.textLayer,
              videoPreview: t.videoPreview,
              defaultText: t.defaultText,
              colors: t.colors.split('|'),
            }}
          />
        ) : null}
        <TextArea
          label={t.caption}
          maxLength={500}
          value={caption}
          onChange={(event) => setCaption(event.currentTarget.value)}
        />
        <Select
          label={t.audience}
          value={audience}
          onChange={(event) => setAudience(event.currentTarget.value as typeof audience)}
        >
          <option value="EVERYONE">{t.everyone}</option>
          <option value="CLOSE_FRIENDS">{t.closeFriends}</option>
        </Select>
        {audience === 'CLOSE_FRIENDS' ? (
          <Link className="font-bold text-brand" to={path('settings/close-friends')}>
            {t.manageCloseFriends}
          </Link>
        ) : null}
        {error && <p role="alert">{error}</p>}
        <Button type="submit" pending={pending}>
          {pending ? t.loading : t.publish}
        </Button>
      </form>
      {editingFile ? (
        <div
          className="fixed inset-0 z-50 grid place-items-center overflow-y-auto bg-black/80 p-4"
          role="dialog"
          aria-modal="true"
        >
          <ImageEditor
            file={editingFile}
            onSave={(edited) => {
              setFile(edited);
              setEditingFile(undefined);
            }}
            onCancel={() => setEditingFile(undefined)}
          />
        </div>
      ) : null}
      {editingVideo ? (
        <div
          className="fixed inset-0 z-50 grid place-items-center overflow-y-auto bg-black/80 p-4"
          role="dialog"
          aria-modal="true"
        >
          <VideoEditor
            file={editingVideo}
            onSave={(edited) => {
              setFile(edited);
              setEditingVideo(undefined);
            }}
            onCancel={() => setEditingVideo(undefined)}
          />
        </div>
      ) : null}
    </div>
  );
}

export function CreateStoryRoute() {
  return (
    <RequireAuth>
      <CreateStory />
    </RequireAuth>
  );
}

export default CreateStoryRoute;
