import { RequireAuth, useSession } from '../../core/session';
import { StoryRail } from './index';

function MyStories() {
  const { user } = useSession();
  return user ? <StoryRail userId={user.id} /> : null;
}

export default function MyStoriesRoute() {
  return (
    <RequireAuth>
      <MyStories />
    </RequireAuth>
  );
}
