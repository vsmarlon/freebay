import { redirect, type LoaderFunctionArgs } from 'react-router';

export function loader({ request }: LoaderFunctionArgs) {
  const locale = request.headers.get('accept-language')?.toLowerCase().startsWith('en') ? 'en' : 'pt-BR';
  return redirect(`/${locale}`);
}
