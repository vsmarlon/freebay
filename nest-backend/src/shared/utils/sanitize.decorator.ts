import { Transform } from 'class-transformer';
import sanitizeHtml = require('sanitize-html');

export function SanitizeText() {
  return Transform(({ value }) => {
    if (typeof value !== 'string') return value;
    return sanitizeHtml(value, {
      allowedTags: [],
      allowedAttributes: {},
      disallowedTagsMode: 'discard',
    });
  });
}
