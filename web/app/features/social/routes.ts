import { type RouteConfig, route } from '@react-router/dev/routes';

export default [
  route('feed', 'features/social/feed.tsx'),
  route('posts/:id', 'features/social/post.tsx'),
  route('posts/mine', 'features/social/collections.tsx'),
  route('liked', 'features/social/collections.tsx'),
  route('saved', 'features/social/saved.tsx'),
  route('search/posts', 'features/social/search.tsx'),
] satisfies RouteConfig;
