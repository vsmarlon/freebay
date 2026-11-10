import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render } from '@testing-library/react';
import type { ReactElement } from 'react';
import { MemoryRouter } from 'react-router';

export function renderWithProviders(ui: ReactElement, route = '/') {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  const tree = (element: ReactElement) => (
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={[route]}>{element}</MemoryRouter>
    </QueryClientProvider>
  );
  const result = render(tree(ui));
  return {
    ...result,
    client,
    rerenderUi: (element: ReactElement) => result.rerender(tree(element)),
  };
}
