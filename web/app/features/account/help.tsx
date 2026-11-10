import { Link } from 'react-router';
import { Frame, Panel, useAccountText } from './account';
import { FaqSections } from './faq-sections';
import { paths } from '../../core/routes';

export default function HelpPage() {
  const { t, path } = useAccountText();
  return (
    <Frame title={t('help')}>
      <Panel>
        <div className="grid gap-5">
          <p>{t('helpIntro')}</p>
          <FaqSections />
          <nav aria-label={t('help')} className="grid gap-3">
            <Link className="min-h-12 bg-brand px-4 py-3 text-on-brand" to={path(paths.bugReport)}>
              {t('bugReport')}
            </Link>
            <Link className="min-h-11 underline" to={path(paths.privacy)}>
              {t('privacy')}
            </Link>
          </nav>
          <p className="text-secondary">{t('legalHelpNote')}</p>
        </div>
      </Panel>
    </Frame>
  );
}
