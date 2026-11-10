import {
  useInfiniteQuery,
  useQuery,
  keepPreviousData,
  type InfiniteData,
  type QueryClient,
} from '@tanstack/react-query';
import { chatRepository } from './repository';
import {
  deletedCopy,
  mergeMessages,
  type ChatMessage,
  type Conversation,
  type CursorPage,
  type MediaKind,
  type Transcript,
} from './model';

// Cache shape: every fetchable piece of the thread lives in TanStack Query.
// ['chat','thread',id] holds one Transcript page per server page (page 0 = the
// newest 50); realtime socket events patch the cached pages below and the
// canonical read-refresh is an invalidate, so there is no second copy of the
// transcript in component state.
export const chatKeys = {
  thread: (id: string) => ['chat', 'thread', id] as const,
  record: (id: string, name: string) => ['chat', 'conversation-record', id, name] as const,
  sidebar: ['chat', 'sidebar'] as const,
  media: (id: string, kind: MediaKind) => ['chat', 'media', id, kind] as const,
  starred: (id: string) => ['chat', 'starred', id] as const,
  forwardTargets: (query: string) => ['chat', 'forward-targets', query] as const,
};

const threadData = (
  data: InfiniteData<Transcript> | undefined,
  update: (pages: Transcript[]) => Transcript[],
): InfiniteData<Transcript> | undefined =>
  data ? { ...data, pages: update(data.pages) } : undefined;

export function threadMessages(pages: Array<Pick<Transcript, 'messages'>>): ChatMessage[] {
  // Pages are stored newest-first ([0]); merging reversed yields oldest → newest
  // iteration, so the freshest copy of a duplicated message wins and the result
  // is ordered chronologically like the merged transcript used to be.
  return mergeMessages(
    [],
    [...pages].reverse().flatMap((page) => page.messages),
  );
}

export function patchThreadMessages(
  client: QueryClient,
  conversationId: string,
  incoming: ChatMessage[],
): void {
  client.setQueryData<InfiniteData<Transcript>>(chatKeys.thread(conversationId), (data) =>
    threadData(data, (pages) =>
      pages.map((page) => ({ ...page, messages: mergeMessages(page.messages, incoming) })),
    ),
  );
}

export function patchThreadMessage(
  client: QueryClient,
  conversationId: string,
  messageId: string,
  update: (message: ChatMessage) => ChatMessage,
): void {
  client.setQueryData<InfiniteData<Transcript>>(chatKeys.thread(conversationId), (data) =>
    threadData(data, (pages) =>
      pages.map((page) => ({
        ...page,
        messages: page.messages.map((message) =>
          message.id === messageId ? update(message) : message,
        ),
      })),
    ),
  );
}

export function deleteThreadMessages(
  client: QueryClient,
  conversationId: string,
  messageIds: string[],
): void {
  const removed = new Set(messageIds);
  client.setQueryData<InfiniteData<Transcript>>(chatKeys.thread(conversationId), (data) =>
    threadData(data, (pages) =>
      pages.map((page) => ({
        ...page,
        messages: page.messages.map((message) =>
          removed.has(message.id) ? deletedCopy(message) : message,
        ),
      })),
    ),
  );
}

const emptyPreference: NonNullable<Transcript['preference']> = {
  theme: 'DEFAULT',
  backgroundUrl: null,
  muted: false,
  isArchived: false,
};

export function threadPreferenceUpdate(
  patch: Partial<NonNullable<Transcript['preference']>>,
): (preference: Transcript['preference']) => Transcript['preference'] {
  return (preference) => ({ ...emptyPreference, ...preference, ...patch });
}

// The thread preference is derived from page 0 (the newest page); only it is patched.
export function updateThreadPreference(
  client: QueryClient,
  conversationId: string,
  update: (preference: Transcript['preference']) => Transcript['preference'],
): void {
  client.setQueryData<InfiniteData<Transcript>>(chatKeys.thread(conversationId), (data) =>
    threadData(data, (pages) =>
      pages.map((page, index) =>
        index === 0 ? { ...page, preference: update(page.preference) } : page,
      ),
    ),
  );
}

export function useThreadTranscript(id: string) {
  return useInfiniteQuery({
    queryKey: chatKeys.thread(id),
    enabled: Boolean(id),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) => chatRepository.transcript(id, pageParam, signal),
    getNextPageParam: (last) => last.nextCursor ?? undefined,
    staleTime: 0,
    // Matches the old single-attempt fetch: the composer surfaces its own error
    // banner immediately instead of waiting out background retries.
    retry: false,
  });
}

// The participant record (product/order info, pending status) arrives from a
// paged conversations lookup; the loop the old probe used becomes pagination:
// pagination stops as soon as the record is found or the pages run out.
export function useConversationRecord(id: string, displayName: string | undefined) {
  return useInfiniteQuery({
    queryKey: chatKeys.record(id, displayName ?? ''),
    enabled: Boolean(id && displayName),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) =>
      chatRepository.conversations({ q: displayName, cursor: pageParam, signal }),
    getNextPageParam: (page) =>
      page.items.some((item) => item.id === id) || !page.nextCursor ? undefined : page.nextCursor,
    staleTime: 30_000,
    retry: false,
  });
}

export const conversationRecordFrom = (
  data: InfiniteData<CursorPage<Conversation>> | undefined,
  id: string,
): Conversation | null =>
  data?.pages.flatMap((page) => page.items).find((item) => item.id === id) ?? null;

export function patchConversationRecord(
  client: QueryClient,
  conversationId: string,
  displayName: string | undefined,
  patch: Partial<Conversation>,
): void {
  client.setQueryData<InfiniteData<CursorPage<Conversation>>>(
    chatKeys.record(conversationId, displayName ?? ''),
    (data) =>
      data
        ? {
            ...data,
            pages: data.pages.map((page) => ({
              ...page,
              items: page.items.map((item) =>
                item.id === conversationId ? { ...item, ...patch } : item,
              ),
            })),
          }
        : data,
  );
}

export function useChatSidebar() {
  return useQuery({
    queryKey: chatKeys.sidebar,
    queryFn: ({ signal }) => chatRepository.conversations({ signal }),
    staleTime: 0,
    refetchOnMount: 'always',
    retry: false,
  });
}

export function useMediaMessages(id: string, kind: MediaKind | null) {
  return useInfiniteQuery({
    queryKey: chatKeys.media(id, kind ?? 'IMAGE'),
    enabled: Boolean(id && kind),
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) =>
      chatRepository.media(id, kind ?? 'IMAGE', pageParam, signal),
    getNextPageParam: (page) => page.nextCursor ?? undefined,
    staleTime: 0,
    retry: false,
  });
}

export function useStarredMessages(id: string, enabled: boolean) {
  return useQuery({
    queryKey: chatKeys.starred(id),
    queryFn: () => chatRepository.starred(id),
    enabled: Boolean(id) && enabled,
    staleTime: 0,
    retry: false,
  });
}

export function useForwardTargets(query: string, enabled: boolean) {
  return useInfiniteQuery({
    queryKey: chatKeys.forwardTargets(query),
    enabled,
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) =>
      chatRepository.conversations({ q: query, cursor: pageParam, signal }),
    getNextPageParam: (page) => page.nextCursor ?? undefined,
    staleTime: 30_000,
    retry: false,
  });
}

export function useInboxConversations(
  userId: string | undefined,
  query: string,
  archived: boolean,
) {
  return useInfiniteQuery({
    queryKey: ['chat', 'inbox', userId ?? '', archived, query],
    // Archived listings search silently (the old payload omitted q in that mode).
    initialPageParam: undefined as string | undefined,
    queryFn: ({ pageParam, signal }) =>
      chatRepository.conversations({
        q: archived ? undefined : query,
        archived,
        cursor: pageParam,
        signal,
      }),
    getNextPageParam: (page) => page.nextCursor ?? undefined,
    staleTime: 0,
    retry: false,
  });
}

export function usePeopleSearch(userId: string | undefined, query: string, enabled: boolean) {
  return useInfiniteQuery({
    queryKey: ['chat', 'people', userId ?? '', query],
    enabled,
    initialPageParam: 0,
    queryFn: ({ pageParam, signal }) => chatRepository.searchUsers(query, pageParam, signal),
    getNextPageParam: (page) => (page.hasMore ? (page.nextOffset ?? undefined) : undefined),
    // Keeps the previous results on screen while a keystroke refetch is in
    // flight, matching the unchanged local list the old state held while typing.
    placeholderData: keepPreviousData,
    staleTime: 0,
    retry: false,
  });
}

export function useNewChatDirectory(userId: string | undefined, enabled: boolean) {
  return useQuery({
    queryKey: ['chat', 'new-chat-directory', userId ?? ''],
    enabled: Boolean(userId) && enabled,
    queryFn: async ({ signal }) => {
      const [blocked, suggestions, following] = await Promise.all([
        chatRepository.blockedUsers(signal),
        chatRepository.suggestions(signal),
        chatRepository.following(userId!, signal),
      ]);
      return {
        blocked: new Set(blocked.users.map((person) => person.id)),
        suggestions: suggestions.users,
        following: following.users,
      };
    },
    staleTime: 30_000,
    retry: false,
  });
}
