import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/safe_link_destination.dart';
import 'package:freebay/core/utils/url_safety_analyzer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class BrutalistSafeLinkDialog extends StatelessWidget {
  final String rawUrl;
  final UrlSafetyResult safetyResult;

  const BrutalistSafeLinkDialog({
    super.key,
    required this.rawUrl,
    required this.safetyResult,
  });

  Future<void> _handleProceed(BuildContext context) async {
    final strings = l10n(context);
    if (safetyResult.isBlocked) {
      AppSnackbar.error(context, strings.safeLinkBlocked);
      return;
    }

    final uri = Uri.tryParse(safetyResult.normalizedUrl);
    if (uri == null) {
      AppSnackbar.error(context, strings.safeLinkInvalid);
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackbar.error(context, strings.safeLinkBrowserFailed);
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, strings.safeLinkOpenFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final isDark = context.isDark;
    final risk = safetyResult.riskLevel;
    final isDangerous =
        risk == UrlRiskLevel.dangerous || safetyResult.isBlocked;
    final isSuspicious = risk == UrlRiskLevel.suspicious;

    final headerColor = isDangerous
        ? AppColors.error
        : (isSuspicious ? AppColors.warning : context.colors.primary);

    final titleText = isDangerous
        ? strings.safeLinkBlockedTitle
        : (isSuspicious
              ? strings.safeLinkSuspiciousTitle
              : strings.safeLinkExternalTitle);

    final badgeText = isDangerous
        ? strings.safeLinkDangerBadge
        : (isSuspicious
              ? strings.safeLinkUnverifiedBadge
              : strings.safeLinkExternalBadge);

    final badgeColor = isDangerous
        ? AppColors.error
        : (isSuspicious ? AppColors.warning : AppColors.success);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surfaceContainerDark
              : AppColors.surfaceContainerLow,
          border: Border.all(color: headerColor, width: 2),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isDangerous
                      ? Icons.gpp_bad_outlined
                      : (isSuspicious
                            ? Icons.warning_amber_outlined
                            : Icons.open_in_new),
                  color: headerColor,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    titleText,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  tooltip: strings.commonClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: badgeColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            SafeLinkDestination(
              host: safetyResult.host,
              normalizedUrl: safetyResult.normalizedUrl,
            ),

            if (safetyResult.riskReasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDangerous
                      ? AppColors.error.withValues(alpha: 0.08)
                      : AppColors.warning.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isDangerous ? AppColors.error : AppColors.warning,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: safetyResult.riskReasons.map((reason) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: isDangerous
                                  ? AppColors.error
                                  : AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 12),

            Text(
              isDangerous
                  ? strings.safeLinkDangerExplanation
                  : strings.safeLinkExternalExplanation,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                height: 1.35,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: strings.safeLinkReturnSafely,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
                if (!isDangerous) ...[
                  const SizedBox(height: 8),
                  AppButton(
                    label: strings.safeLinkContinueExternal,
                    onPressed: () => _handleProceed(context),
                    variant: AppButtonVariant.secondary,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showBrutalistSafeLinkDialog(
  BuildContext context,
  String rawUrl,
) async {
  final safetyResult = UrlSafetyAnalyzer.analyze(rawUrl);

  return showDialog(
    context: context,
    builder: (ctx) =>
        BrutalistSafeLinkDialog(rawUrl: rawUrl, safetyResult: safetyResult),
  );
}
