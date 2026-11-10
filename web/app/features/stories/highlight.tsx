import { useParams } from 'react-router';
import { RequireAuth } from '../../core/session';
import { useStories, type Highlight } from './shared';
import { StoryPlayer } from './player';

export function HighlightViewer() {
  const { id = '' } = useParams();
  const { value, error, retry } = useStories<Highlight>(
    `/stories/highlights/${encodeURIComponent(id)}`,
    id,
  );
  return (
    <StoryPlayer
      stories={value?.stories ?? []}
      title={value?.title}
      user={value?.user}
      error={error}
      retry={retry}
      loading={!value}
    />
  );
}

export function HighlightViewerRoute() {
  return (
    <RequireAuth>
      <HighlightViewer />
    </RequireAuth>
  );
}

export default HighlightViewerRoute;
