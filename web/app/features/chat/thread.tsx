import { useParams } from 'react-router';
import { RequireAuth, useSession } from '../../core/session';
import { chatRepository } from './repository';
import { ThreadPage } from './thread/thread-page';

export async function startConversation(targetUserId: string, productId?: string) {
  return chatRepository.start(targetUserId, productId);
}

function KeyedThreadPage() {
  const { id = '', locale = 'pt-BR' } = useParams();
  const { user } = useSession();
  return <ThreadPage key={`${user?.id}:${id}`} conversationId={id} locale={locale} />;
}

export default function ChatThreadPage() {
  return (
    <RequireAuth>
      <KeyedThreadPage />
    </RequireAuth>
  );
}
