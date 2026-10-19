function normalizeOrigin(value: string): string | null {
  try {
    const url = new URL(value);
    if (
      !['http:', 'https:'].includes(url.protocol) ||
      url.username || url.password || url.pathname !== '/' || url.search || url.hash
    ) return null;
    return url.origin;
  } catch {
    return null;
  }
}

export function parseAllowedOrigins(value: string): readonly string[] {
  return value.split(',').flatMap((origin) => {
    const normalized = normalizeOrigin(origin.trim());
    return normalized ? [normalized] : [];
  });
}

export function configuredAllowedOrigins(): readonly string[] {
  return parseAllowedOrigins(
    process.env.ALLOWED_ORIGINS ?? process.env.WEB_APP_URL ?? process.env.WEB_ALLOWED_ORIGIN ?? 'http://localhost:3000',
  );
}

export function isAllowedOrigin(origin: string | undefined, allowed: readonly string[]): boolean {
  if (origin === undefined) return true;
  const normalized = normalizeOrigin(origin);
  return normalized !== null && allowed.includes(normalized);
}
