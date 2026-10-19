import { expect, it } from 'vitest';
import { serializeStoryTextBlocks, type StoryTextBlock } from './text-block-editor';

it('serializes positioned overlay metadata in layer order without flattening it into media', () => {
  const blocks: StoryTextBlock[] = [
    { id: 'second', text: ' second ', x: .8, y: .2, scale: 1.5, rotation: .4, color: 0xfff59e0b, style: 'strong', zIndex: 2 },
    { id: 'first', text: 'first', x: .25, y: .7, scale: .75, rotation: -.2, color: 0xff8a1083, style: 'editorial', zIndex: 1 },
  ];

  expect(JSON.parse(serializeStoryTextBlocks(blocks))).toEqual([
    { id: 'first', text: 'first', x: .25, y: .7, scale: .75, rotation: -.2, color: 0xff8a1083, style: 'editorial', zIndex: 1 },
    { id: 'second', text: 'second', x: .8, y: .2, scale: 1.5, rotation: .4, color: 0xfff59e0b, style: 'strong', zIndex: 2 },
  ]);
});
