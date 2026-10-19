import { Outlet, redirect, type LoaderFunctionArgs } from 'react-router';

export function loader({ params }: LoaderFunctionArgs) {
  if (params.locale !== 'en' && params.locale !== 'pt-BR') return redirect('/pt-BR');
  return null;
}

export default function LocaleLayout() { return <Outlet />; }
