import { commerceApi } from './api';

export { commerceApi } from './api';
export { default as commerceRoutes } from './routes';
export const cartApi = { addToCart: commerceApi.addToCart };
