import { useAccountText } from './account';

const sections = [
  {
    title: 'faqAccountProfile',
    items: [
      ['faqCreateAccountQuestion', 'faqCreateAccountAnswer'],
      ['faqEditProfileQuestion', 'faqEditProfileAnswer'],
      ['faqForgotPasswordQuestion', 'faqForgotPasswordAnswer'],
      ['faqBiometryQuestion', 'faqBiometryAnswer'],
    ],
  },
  {
    title: 'faqPurchasesPayments',
    items: [
      ['faqBuyProductQuestion', 'faqBuyProductAnswer'],
      ['faqEscrowQuestion', 'faqEscrowAnswer'],
      ['faqCartQuestion', 'faqCartAnswer'],
      ['faqPaymentMethodsQuestion', 'faqPaymentMethodsAnswer'],
      ['faqInstallmentsQuestion', 'faqInstallmentsAnswer'],
    ],
  },
  {
    title: 'faqSalesWallet',
    items: [
      ['faqListProductQuestion', 'faqListProductAnswer'],
      ['faqSellingFeeQuestion', 'faqSellingFeeAnswer'],
      ['faqPayoutQuestion', 'faqPayoutAnswer'],
      ['faqPixWithdrawalQuestion', 'faqPixWithdrawalAnswer'],
    ],
  },
  {
    title: 'faqCancellationRefunds',
    items: [
      ['faqCancelOrderQuestion', 'faqCancelOrderAnswer'],
      ['faqRefundQuestion', 'faqRefundAnswer'],
      ['faqStockQuestion', 'faqStockAnswer'],
      ['faqCancelReasonQuestion', 'faqCancelReasonAnswer'],
    ],
  },
  {
    title: 'faqDisputesSecurity',
    items: [
      ['faqMissingProductQuestion', 'faqMissingProductAnswer'],
      ['faqDefectiveProductQuestion', 'faqDefectiveProductAnswer'],
      ['faqSecureChatQuestion', 'faqSecureChatAnswer'],
      ['faqBankDataQuestion', 'faqBankDataAnswer'],
    ],
  },
] as const;

export function FaqSections() {
  const { t } = useAccountText();
  return (
    <>
      {sections.map((section) => (
        <section className="grid gap-2" key={section.title}>
          <h2 className="font-display text-xl font-bold">{t(section.title)}</h2>
          {section.items.map(([question, answer]) => (
            <details key={question} className="bg-surface-mid p-4">
              <summary className="min-h-10 cursor-pointer font-semibold">{t(question)}</summary>
              <p className="mt-3">{t(answer)}</p>
            </details>
          ))}
        </section>
      ))}
    </>
  );
}
