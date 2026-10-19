import { type RouteConfig, route } from '@react-router/dev/routes';

export default [
  route('profile', 'features/account/profile.tsx'),
  route('people/:id', 'features/account/profile.tsx'),
  route('people/:id/followers', 'features/account/connections.tsx'),
  route('people/:id/following', 'features/account/connections.tsx'),
  route('profile/followers', 'features/account/connections.tsx'),
  route('profile/following', 'features/account/connections.tsx'),
  route('profile/edit', 'features/account/edit-profile.tsx'),
  route('search/people', 'features/account/people.tsx'),
  route('settings', 'features/account/settings.tsx'),
  route('settings/privacy', 'features/account/privacy.tsx'),
  route('settings/close-friends', 'features/account/close-friends.tsx'),
  route('settings/blocked', 'features/account/safety-list.tsx'),
  route('settings/restricted', 'features/account/safety-list.tsx'),
  route('notifications', 'features/account/notifications.tsx'),
  route('help', 'features/account/help.tsx'),
  route('help/bug-report', 'features/account/bug-report.tsx'),
] satisfies RouteConfig;
