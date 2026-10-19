import { Link, useParams } from 'react-router';

export default function NotFoundPage() {
  const { locale = 'pt-BR' } = useParams();
  const english = locale === 'en';
  return <main className="mx-auto grid min-h-[60vh] max-w-3xl content-center gap-4 px-6 text-ink">
    <p className="font-display text-6xl font-black">404</p>
    <h1 className="font-display text-3xl font-bold">{english ? 'Page not found' : 'Página não encontrada'}</h1>
    <p>{english ? 'That Freebay page does not exist.' : 'Essa página do Freebay não existe.'}</p>
    <Link className="ui-button ui-primary w-fit" to={`/${english ? 'en' : 'pt-BR'}`}>{english ? 'Go home' : 'Ir para o início'}</Link>
  </main>;
}
