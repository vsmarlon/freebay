import { fireEvent, screen } from '@testing-library/react';
import { expect, it } from 'vitest';
import { renderWithProviders } from '../../../tests/render-with-providers';
import { AppShell } from './index';

// jsdom ships no matchMedia; the header's scroll-chrome ref only needs the listener API.
function stubMatchMedia() {
  window.matchMedia = (query: string): MediaQueryList => ({
    matches: false,
    media: query,
    onchange: null,
    addEventListener: () => {},
    removeEventListener: () => {},
    addListener: () => {},
    removeListener: () => {},
    dispatchEvent: () => false,
  });
}

it('opens the account menu on click and closes it on Escape', () => {
  stubMatchMedia();
  renderWithProviders(<AppShell>content</AppShell>);
  const trigger = screen.getByRole('button', { name: 'Conta' });
  expect(screen.queryByRole('menu')).toBeNull();
  fireEvent.click(trigger);
  expect(trigger).toHaveAttribute('aria-expanded', 'true');
  expect(screen.getByRole('menu')).toBeInTheDocument();
  fireEvent.keyDown(trigger, { key: 'Escape' });
  expect(trigger).toHaveAttribute('aria-expanded', 'false');
  expect(screen.queryByRole('menu')).toBeNull();
});
