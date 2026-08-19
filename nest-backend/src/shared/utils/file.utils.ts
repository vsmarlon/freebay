export function toDataUri(file: { mimetype: string; buffer: Buffer }): string {
  return `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
}
