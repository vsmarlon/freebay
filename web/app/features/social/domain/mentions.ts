export type MentionRange = Readonly<{ start: number; term: string }>;

export function findMention(text: string, caret: number): MentionRange | null {
  const match = /@([\w-]*)$/.exec(text.slice(0, caret));
  return match ? { start: caret - match[0].length, term: match[1] } : null;
}

export function replaceMention(
  content: string,
  range: MentionRange,
  user: { username?: string | null; displayName: string },
): string {
  const end = range.start + 1 + range.term.length;
  const replacement = user.username ? `@${user.username} ` : `${user.displayName} `;
  return content.slice(0, range.start) + replacement + content.slice(end);
}
