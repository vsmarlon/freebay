import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  List<Map<String, dynamic>> _sections(AppLocalizations strings) => [
    {
      'title': strings.faqAccountProfile,
      'items': [
        {
          'q': strings.faqCreateAccountQuestion,
          'a': strings.faqCreateAccountAnswer,
        },
        {
          'q': strings.faqEditProfileQuestion,
          'a': strings.faqEditProfileAnswer,
        },
        {
          'q': strings.faqForgotPasswordQuestion,
          'a': strings.faqForgotPasswordAnswer,
        },
        {'q': strings.faqBiometryQuestion, 'a': strings.faqBiometryAnswer},
      ],
    },
    {
      'title': strings.faqPurchasesPayments,
      'items': [
        {'q': strings.faqBuyProductQuestion, 'a': strings.faqBuyProductAnswer},
        {'q': strings.faqEscrowQuestion, 'a': strings.faqEscrowAnswer},
        {'q': strings.faqCartQuestion, 'a': strings.faqCartAnswer},
        {
          'q': strings.faqPaymentMethodsQuestion,
          'a': strings.faqPaymentMethodsAnswer,
        },
        {
          'q': strings.faqInstallmentsQuestion,
          'a': strings.faqInstallmentsAnswer,
        },
      ],
    },
    {
      'title': strings.faqSalesWallet,
      'items': [
        {
          'q': strings.faqListProductQuestion,
          'a': strings.faqListProductAnswer,
        },
        {'q': strings.faqSellingFeeQuestion, 'a': strings.faqSellingFeeAnswer},
        {'q': strings.faqPayoutQuestion, 'a': strings.faqPayoutAnswer},
        {
          'q': strings.faqPixWithdrawalQuestion,
          'a': strings.faqPixWithdrawalAnswer,
        },
      ],
    },
    {
      'title': strings.faqCancellationRefunds,
      'items': [
        {
          'q': strings.faqCancelOrderQuestion,
          'a': strings.faqCancelOrderAnswer,
        },
        {'q': strings.faqRefundQuestion, 'a': strings.faqRefundAnswer},
        {'q': strings.faqStockQuestion, 'a': strings.faqStockAnswer},
        {
          'q': strings.faqCancelReasonQuestion,
          'a': strings.faqCancelReasonAnswer,
        },
      ],
    },
    {
      'title': strings.faqDisputesSecurity,
      'items': [
        {
          'q': strings.faqMissingProductQuestion,
          'a': strings.faqMissingProductAnswer,
        },
        {
          'q': strings.faqDefectiveProductQuestion,
          'a': strings.faqDefectiveProductAnswer,
        },
        {'q': strings.faqSecureChatQuestion, 'a': strings.faqSecureChatAnswer},
        {'q': strings.faqBankDataQuestion, 'a': strings.faqBankDataAnswer},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final sections = _sections(strings);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.chatFaqTitle,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                itemCount: sections.length,
                itemBuilder: (context, sIndex) {
                  final sec = sections[sIndex];
                  final items = sec['items'] as List<Map<String, String>>;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          sec['title'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: context.textSecondary,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      ...items.map(
                        (item) =>
                            _FaqTile(question: item['q']!, answer: item['a']!),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border.all(color: context.borderColor, width: 1.5),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.remove : Icons.add,
                    size: 18,
                    color: context.textPrimary,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              color: context.surfaceColor,
              child: Text(
                widget.answer,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: context.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
