import { useParams } from 'react-router';
import { RequireAuth } from '../../core/session';
import { useStories, type Story } from './shared';
import { StoryPlayer } from './player';

export function StoryViewer() {
  const { userId = '' } = useParams();
  const { value, error, retry } = useStories<Story[]>(`/stories/user/${encodeURIComponent(userId)}`, userId);
  const stories = value ?? [];
  return <StoryPlayer stories={stories} user={stories[0]?.user} error={error} retry={retry} loading={!value} />;
}

export function StoryViewerRoute() { return <RequireAuth><StoryViewer /></RequireAuth>; }

export function loader() {
  return null;
}
