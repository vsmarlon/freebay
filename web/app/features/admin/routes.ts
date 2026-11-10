import type { RouteConfig } from '@react-router/dev/routes';
import { index, route } from '@react-router/dev/routes';

export default [
  route('admin', 'features/admin/layout.tsx', [
    index('features/admin/disputes.tsx'),
    route('reports', 'features/admin/reports.tsx'),
  ]),
] satisfies RouteConfig;
