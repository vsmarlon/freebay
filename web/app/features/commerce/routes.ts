import { type RouteConfig, route } from '@react-router/dev/routes';

export default [
  route('cart', 'features/commerce/cart.tsx'),
  route('checkout', 'features/commerce/checkout.tsx'),
  route('orders', 'features/commerce/orders.tsx'),
  route('sales', 'features/commerce/sales.tsx'),
  route('orders/:id', 'features/commerce/order.tsx'),
  route('orders/:id/review', 'features/commerce/review.tsx'),
  route('orders/:id/dispute', 'features/commerce/open-dispute.tsx'),
  route('disputes', 'features/commerce/disputes.tsx'),
  route('disputes/:id', 'features/commerce/dispute.tsx'),
  route('wallet', 'features/commerce/wallet.tsx'),
  route('payments/success', 'features/commerce/payment-return.tsx', {
    id: 'commerce-payment-success',
  }),
  route('payments/cancel', 'features/commerce/payment-return.tsx', {
    id: 'commerce-payment-cancel',
  }),
] satisfies RouteConfig;
