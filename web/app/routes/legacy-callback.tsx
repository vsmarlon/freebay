import { redirect, type LoaderFunctionArgs } from 'react-router';

const destinations: Record<string, string> = {
  '/payments/success': 'payments/success',
  '/payments/cancel': 'payments/cancel',
  '/wallet/connect/refresh': 'wallet',
  '/wallet/connect/return': 'wallet',
};

export function localizedCallbackLocation(request: Request): string {
  const incoming = new URL(request.url);
  const destination = destinations[incoming.pathname];
  if (!destination) throw new Response('Not found', { status: 404 });
  const preferred = request.headers
    .get('accept-language')
    ?.split(',')
    .map((item) => item.trim().split(';', 1)[0]?.toLowerCase())
    .find((language) => language?.startsWith('en') || language?.startsWith('pt'));
  const locale = preferred?.startsWith('en') ? 'en' : 'pt-BR';
  return `/${locale}/${destination}${incoming.search}`;
}

export function loader({ request }: LoaderFunctionArgs) {
  return redirect(localizedCallbackLocation(request), 302);
}

export default function LegacyCallbackRoute() {
  return null;
}
