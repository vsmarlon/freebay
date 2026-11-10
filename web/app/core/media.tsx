import { useQuery } from '@tanstack/react-query';
import { api } from './api';
import { useSession } from './session';
import { useI18n } from './locale';

export function mediaUrl(src: string): string {
  const url = new URL(
    src,
    typeof window === 'undefined' ? 'https://freebay.invalid' : window.location.origin,
  );
  if (!['http:', 'https:'].includes(url.protocol)) throw new TypeError('Unsupported media URL');
  return url.origin === 'https://freebay.invalid' ? `${url.pathname}${url.search}` : url.toString();
}

export function useMediaUrl(src: string | null | undefined, enabled = true) {
  const { user, isSigningOut } = useSession();
  // ponytail: external story media is public and must not go through the authenticated blob endpoint.
  const external = Boolean(src && /^https?:\/\//.test(src));
  const query = useQuery<string | null>({
    queryKey: ['media', user?.id ?? '', src ?? ''],
    enabled: Boolean(src && !external && enabled && user && !isSigningOut),
    queryFn: async ({ signal }) => {
      const blob = await api.blob(src!, { signal });
      return URL.createObjectURL(blob);
    },
    staleTime: Infinity,
    gcTime: 5 * 60 * 1000,
    retry: false,
  });
  if (!src || !enabled) return { url: null, isPending: false, error: undefined };
  if (external) return { url: mediaUrl(src), isPending: false, error: undefined };
  if (!user || isSigningOut) return { url: null, isPending: false, error: undefined };
  return { url: query.data ?? null, isPending: query.isPending, error: query.error };
}

export function AuthenticatedMedia({
  src,
  type,
  alt = '',
  enabled = true,
  className,
}: {
  src: string | null | undefined;
  type: 'image' | 'video' | 'audio';
  alt?: string;
  enabled?: boolean;
  className?: string;
}) {
  const media = useMediaUrl(src, enabled);
  const { t } = useI18n();
  if (!media.url)
    return media.isPending ? (
      <span role="status">{t('common.loading')}</span>
    ) : media.error ? (
      <span role="alert">{t('common.error')}</span>
    ) : null;
  if (type === 'image') return <img src={media.url} alt={alt} className={className} />;
  if (type === 'video') return <video src={media.url} controls className={className} />;
  return <audio src={media.url} controls className={className} />;
}
