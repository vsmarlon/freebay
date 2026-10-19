import { Link } from 'react-router';
import { Frame, Panel, useAccountText } from './account';
import { paths } from '../../core/routes';

const sections = [
  { title: 'faqAccountProfile', items: [['faqCreateAccountQuestion', 'faqCreateAccountAnswer'], ['faqEditProfileQuestion', 'faqEditProfileAnswer'], ['faqForgotPasswordQuestion', 'faqForgotPasswordAnswer'], ['faqBiometryQuestion', 'faqBiometryAnswer']] },
  { title: 'faqPurchasesPayments', items: [['faqBuyProductQuestion', 'faqBuyProductAnswer'], ['faqEscrowQuestion', 'faqEscrowAnswer'], ['faqCartQuestion', 'faqCartAnswer'], ['faqPaymentMethodsQuestion', 'faqPaymentMethodsAnswer'], ['faqInstallmentsQuestion', 'faqInstallmentsAnswer']] },
  { title: 'faqSalesWallet', items: [['faqListProductQuestion', 'faqListProductAnswer'], ['faqSellingFeeQuestion', 'faqSellingFeeAnswer'], ['faqPayoutQuestion', 'faqPayoutAnswer'], ['faqPixWithdrawalQuestion', 'faqPixWithdrawalAnswer']] },
  { title: 'faqCancellationRefunds', items: [['faqCancelOrderQuestion', 'faqCancelOrderAnswer'], ['faqRefundQuestion', 'faqRefundAnswer'], ['faqStockQuestion', 'faqStockAnswer'], ['faqCancelReasonQuestion', 'faqCancelReasonAnswer']] },
  { title: 'faqDisputesSecurity', items: [['faqMissingProductQuestion', 'faqMissingProductAnswer'], ['faqDefectiveProductQuestion', 'faqDefectiveProductAnswer'], ['faqSecureChatQuestion', 'faqSecureChatAnswer'], ['faqBankDataQuestion', 'faqBankDataAnswer']] },
] as const;

export default function HelpPage() {
  const { t, path } = useAccountText();
  return <Frame title={t('help')}><Panel><div className="grid gap-5"><p>{t('helpIntro')}</p>{sections.map((section) => <section className="grid gap-2" key={section.title}><h2 className="font-display text-xl font-bold">{t(section.title)}</h2>{section.items.map(([question, answer]) => <details key={question} className="bg-surface-mid p-4"><summary className="min-h-10 cursor-pointer font-semibold">{t(question)}</summary><p className="mt-3">{t(answer)}</p></details>)}</section>)}<nav aria-label={t('help')} className="grid gap-3"><Link className="min-h-12 bg-brand px-4 py-3 text-on-brand" to={path(paths.bugReport)}>{t('bugReport')}</Link><Link className="min-h-11 underline" to={path(paths.privacy)}>{t('privacy')}</Link></nav><p className="text-secondary">{t('legalHelpNote')}</p></div></Panel></Frame>;
}
