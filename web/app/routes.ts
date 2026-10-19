import { type RouteConfigEntry, type RouteConfig, index, layout, route } from '@react-router/dev/routes';
import accountRoutes from './features/account/routes';
import authRoutes from './features/auth/routes';
import commerceRoutes from './features/commerce/routes';
import marketplaceRoutes from './features/marketplace/routes';
import socialRoutes from './features/social/routes';

function uniqueIds(entries: RouteConfigEntry[], group: string): RouteConfigEntry[] {
  return entries.map((entry, index) => ({
    ...entry,
    id: `${group}-${index}`,
    ...(entry.children ? { children: uniqueIds(entry.children, `${group}-${index}`) } : {}),
  }));
}

export default [
  route('/', 'routes/locale-redirect.tsx'),
  route('payments/success', 'routes/legacy-callback.tsx', { id: 'legacy-payment-success' }),
  route('payments/cancel', 'routes/legacy-callback.tsx', { id: 'legacy-payment-cancel' }),
  route('wallet/connect/refresh', 'routes/legacy-callback.tsx', { id: 'legacy-connect-refresh' }),
  route('wallet/connect/return', 'routes/legacy-callback.tsx', { id: 'legacy-connect-return' }),
  route(':locale', 'routes/locale-layout.tsx', [
    index('routes/marketing.tsx', { id: 'marketing-home' }),
    route('about', 'routes/marketing.tsx', { id: 'marketing-about' }),
    route('how-it-works', 'routes/marketing.tsx', { id: 'marketing-how-it-works' }),
    route('onboarding', 'features/onboarding/index.tsx'),
    route('welcome', 'features/onboarding/welcome.tsx', { id: 'welcome-setup' }),
    ...uniqueIds(authRoutes, 'auth'),
    layout('routes/app-layout.tsx', [
      ...uniqueIds(marketplaceRoutes, 'marketplace'),
      ...uniqueIds(socialRoutes, 'social'),
      ...uniqueIds(accountRoutes, 'account'),
      ...uniqueIds(commerceRoutes, 'commerce'),
      route('stories', 'features/stories/index.tsx', { id: 'stories-index' }),
      route('stories/new', 'features/stories/create.tsx', { id: 'stories-create' }),
      route('stories/mine', 'features/stories/mine.tsx', { id: 'stories-mine' }),
      route('stories/archive', 'features/stories/archive.tsx', { id: 'stories-archive' }),
      route('stories/:userId', 'features/stories/viewer.tsx', { id: 'stories-viewer' }),
      route('highlights/:id', 'features/stories/highlight.tsx', { id: 'stories-highlights' }),
      route('messages', 'features/chat/inbox.tsx', { id: 'chat-inbox' }),
      route('messages/:id', 'features/chat/thread.tsx', { id: 'chat-thread' }),
    ]),
    route('*', 'routes/not-found.tsx', { id: 'localized-not-found' }),
  ]),
] satisfies RouteConfig;
