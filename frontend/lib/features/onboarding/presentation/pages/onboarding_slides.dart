import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class OnboardingSlide {
  final IconData icon;
  final String stepTag;
  final String title;
  final String subtitle;
  final String body;
  final List<String> highlights;

  const OnboardingSlide({
    required this.icon,
    required this.stepTag,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.highlights,
  });
}

List<OnboardingSlide> onboardingSlides(AppLocalizations strings) => [
  OnboardingSlide(
    icon: Icons.storefront_outlined,
    stepTag: strings.onboardingStepSocial,
    title: strings.onboardingShopAndSell,
    subtitle: strings.onboardingSocialFeed,
    body: strings.onboardingSocialBody,
    highlights: [
      strings.onboardingHighlightListings,
      strings.onboardingHighlightFeed,
      strings.onboardingHighlightReach,
    ],
  ),
  OnboardingSlide(
    icon: Icons.chat_bubble_outline_rounded,
    stepTag: strings.onboardingStepNegotiation,
    title: strings.onboardingChatAndEscrow,
    subtitle: strings.onboardingProtection,
    body: strings.onboardingNegotiationBody,
    highlights: [
      strings.onboardingHighlightChat,
      strings.onboardingHighlightHeldPayment,
      strings.onboardingHighlightDisputes,
    ],
  ),
  OnboardingSlide(
    icon: Icons.account_balance_wallet_outlined,
    stepTag: strings.onboardingStepWallet,
    title: strings.onboardingPayouts,
    subtitle: strings.onboardingMoneyControl,
    body: strings.onboardingWalletBody,
    highlights: [
      strings.onboardingHighlightPayout,
      strings.onboardingHighlightReviews,
      strings.onboardingHighlightStatement,
    ],
  ),
];

class OnboardingSlideView extends StatelessWidget {
  final OnboardingSlide slide;
  final double pageOffset;

  const OnboardingSlideView({
    super.key,
    required this.slide,
    required this.pageOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: Offset(pageOffset * -60, 0),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                  border: Border.all(
                    color: Colors.white.withAlpha(40),
                    width: 2,
                  ),
                ),
                child: Icon(slide.icon, size: 56, color: AppColors.white),
              ),
            ),
          ),
          Spacing.vXl,
          Transform.translate(
            offset: Offset(pageOffset * -40, 0),
            child: Column(
              children: [
                Text(
                  slide.stepTag,
                  style: AppTypography.brutalistTag.copyWith(
                    color: AppColors.primaryContainer,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacing.vXs,
                Text(
                  slide.title,
                  style: AppTypography.h1.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  slide.subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Spacing.vMd,
          Transform.translate(
            offset: Offset(pageOffset * -20, 0),
            child: Text(
              slide.body,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Spacing.vLg,
          Transform.translate(
            offset: Offset(pageOffset * -10, 0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: slide.highlights.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.brutalistTag.copyWith(
                      color: context.textPrimary,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
