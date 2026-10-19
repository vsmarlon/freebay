import { route } from '@react-router/dev/routes';

export default [
  route('login', 'features/auth/login.tsx'),
  route('register', 'features/auth/register.tsx'),
  route('verify-email', 'features/auth/verify-email.tsx'),
  route('verify-action', 'features/auth/verify-action.tsx'),
  route('complete-profile', 'features/auth/complete-profile.tsx'),
  route('forgot-password', 'features/auth/forgot-password.tsx'),
  route('reset-password', 'features/auth/reset-password.tsx'),
];
