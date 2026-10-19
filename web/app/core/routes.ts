const segment = (value: string) => encodeURIComponent(value);
export const paths = { home: '', onboarding: 'onboarding', welcome: 'welcome', login: 'login', register: 'register', verifyEmail: 'verify-email', completeProfile: 'complete-profile', forgotPassword: 'forgot-password', resetPassword: 'reset-password', feed: 'feed', explore: 'explore', search: 'search', peopleSearch: 'search/people', categories: 'categories', sell: 'sell', favorites: 'favorites', liked: 'liked', saved: 'saved', cart: 'cart', checkout: 'checkout', orders: 'orders', sales: 'sales', wallet: 'wallet', disputes: 'disputes', messages: 'messages', notifications: 'notifications', settings: 'settings', profile: 'profile', editProfile: 'profile/edit', myPosts: 'posts/mine', myProducts: 'products/mine', myStories: 'stories/mine', closeFriends: 'settings/close-friends', privacy: 'settings/privacy', blocked: 'settings/blocked', restricted: 'settings/restricted', help: 'help', bugReport: 'help/bug-report', storyArchive: 'stories/archive', product: (id: string) => `products/${segment(id)}`, editProduct: (id: string) => `products/${segment(id)}/edit`, post: (id: string) => `posts/${segment(id)}`, person: (id: string) => `people/${segment(id)}`, userReviews: (id: string) => `people/${segment(id)}/reviews`, conversation: (id: string) => `messages/${segment(id)}`, order: (id: string) => `orders/${segment(id)}`, reviewOrder: (id: string) => `orders/${segment(id)}/review`, disputeOrder: (id: string) => `orders/${segment(id)}/dispute`, dispute: (id: string) => `disputes/${segment(id)}`, story: (id: string) => `stories/${segment(id)}`, highlights: (userId: string) => `highlights/${segment(userId)}` } as const;
export function appPath(locale: 'pt-BR' | 'en', relativePath = ''): string { return `/${locale}${relativePath ? `/${relativePath.replace(/^\/+|\/+$/g, '')}` : ''}`; }
export function safeLocalizedReturnTo(value: string | null | undefined, locale: 'pt-BR' | 'en', fallback = appPath(locale, paths.feed)) {
  if (!value || !value.startsWith('/') || value.startsWith('//') || value.includes('\\')) return fallback;
  try {
    const target = new URL(value, 'https://freebay.invalid');
    const prefix = `/${locale}`;
    if (target.origin !== 'https://freebay.invalid' || (target.pathname !== prefix && !target.pathname.startsWith(`${prefix}/`))) return fallback;
    const firstRoute = target.pathname.slice(prefix.length).split('/').filter(Boolean)[0];
    if (['login', 'register', 'onboarding', 'welcome', 'complete-profile', 'verify-email', 'verify-action', 'forgot-password', 'reset-password'].includes(firstRoute ?? '')) return fallback;
    return `${target.pathname}${target.search}${target.hash}`;
  } catch { return fallback; }
}
export const pathsFor = paths;
