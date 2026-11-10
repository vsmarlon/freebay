import { render, screen } from '@testing-library/react';
import { expect, it } from 'vitest';
import { PageSection } from './page-section';

it('renders the shared page shell and appends caller classes', () => {
  render(<PageSection className="space-y-4">content</PageSection>);
  const section = screen.getByText('content');
  expect(section.tagName).toBe('SECTION');
  expect(section).toHaveClass('page-section');
  expect(section).toHaveClass('space-y-4');
});
