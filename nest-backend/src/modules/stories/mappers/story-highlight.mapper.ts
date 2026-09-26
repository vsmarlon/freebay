import { HighlightPayload } from '../data/repositories/story-highlight-database.repository';
import { canonicalStoryTextBlocks } from '../dtos/stories.dto';

export function toHighlightResponse(highlight: HighlightPayload) {
  const stories = highlight.stories
    .filter(({ story }) => story.deletedAt === null)
    .map(({ story }) => ({
      id: story.id,
      imageUrl: story.imageUrl,
      mediaType: story.mediaType,
      caption: story.caption,
      textBlocks: canonicalStoryTextBlocks(story.textBlocks),
      createdAt: story.createdAt,
      expiresAt: story.expiresAt,
    }));
  return {
    id: highlight.id,
    title: highlight.title,
    user: highlight.user,
    coverStoryId: highlight.coverStoryId,
    coverUrl: stories.find((story) => story.id === highlight.coverStoryId)?.imageUrl ?? stories[0]?.imageUrl ?? '',
    stories,
  };
}
