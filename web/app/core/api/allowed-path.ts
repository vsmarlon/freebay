/** Same-origin guard: the browser client never sends credentials to another origin. */
export const allowedPath = (path: string) =>
  path.startsWith('/') &&
  !path.startsWith('//') &&
  !path.startsWith('/\\') &&
  new URL(path, location.origin).origin === location.origin;
