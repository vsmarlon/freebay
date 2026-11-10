import type { Conversation } from './model';

export function groupConversationsByCounterparty(conversations: Conversation[]) {
  const groups = new Map<string, Conversation[]>();
  for (const conversation of conversations) {
    const group = groups.get(conversation.otherUser.id) ?? [];
    group.push(conversation);
    groups.set(conversation.otherUser.id, group);
  }
  return groups;
}
