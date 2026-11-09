import { route, type RouteConfig } from '@react-router/dev/routes';

export default [
  route('explore', 'features/marketplace/catalog.tsx', { id: 'marketplace-explore' }),
  route('search', 'features/marketplace/catalog.tsx', { id: 'marketplace-search' }),
  route('categories', 'features/marketplace/categories.tsx', { id: 'marketplace-categories' }),
  route('products/:id', 'features/marketplace/detail.tsx', { id: 'marketplace-product' }),
  route('products/:id/buy', 'features/marketplace/buy.tsx', { id: 'marketplace-buy' }),
  route('products/mine', 'features/marketplace/my-products.tsx', { id: 'marketplace-my-products' }),
  route('people/:id/reviews', 'features/marketplace/user-reviews.tsx', {
    id: 'marketplace-user-reviews',
  }),
  route('sell', 'features/marketplace/editor.tsx', { id: 'marketplace-sell' }),
  route('products/:id/edit', 'features/marketplace/editor.tsx', { id: 'marketplace-product-edit' }),
  route('favorites', 'features/marketplace/favorites.tsx', { id: 'marketplace-favorites' }),
] satisfies RouteConfig;
