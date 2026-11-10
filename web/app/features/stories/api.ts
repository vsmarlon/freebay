import type { Highlight } from './shared';
import { api } from '../../core/api';

export type HighlightBody = {
  title: string;
  coverUrl?: string | null;
  coverStoryId?: string;
  storyIds?: string[];
};

export const storiesApi = {
  get: <T>(path: string, signal?: AbortSignal) => api.get<T>(path, { signal }),
  create: (form: FormData) => api.post('/stories', form),
  highlightsOfUser: (userId: string, signal?: AbortSignal) =>
    api.get<{ highlights: Highlight[] }>(`/stories/highlights/user/${encodeURIComponent(userId)}`, {
      signal,
    }),
  view: (storyId: string) => api.post(`/stories/${encodeURIComponent(storyId)}/view`),
  saveHighlight: (highlightId: string | null, body: HighlightBody) =>
    highlightId
      ? api.patch(`/stories/highlights/${encodeURIComponent(highlightId)}`, body)
      : api.post('/stories/highlights', body),
  deleteStory: (storyId: string) => api.patch(`/stories/${encodeURIComponent(storyId)}/delete`),
  deleteHighlight: (highlightId: string) =>
    api.patch(`/stories/highlights/${encodeURIComponent(highlightId)}/delete`),
};
