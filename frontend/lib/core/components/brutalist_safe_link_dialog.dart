import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/utils/url_safety_analyzer.dart';
import 'package:url_launcher/url_launcher.dart';

/// Digital Brutalist interstitial security dialog displayed before navigating to external URLs.
class BrutalistSafeLinkDialog extends StatelessWidget {
  final String rawUrl;
  final UrlSafetyResult safetyResult;

  const BrutalistSafeLinkDialog({
    super.key,
    required this.rawUrl,
    required this.safetyResult,
  });

  Future<void> _handleProceed(BuildContext context) async {
    if (safetyResult.isBlocked) {
      AppSnackbar.error(
        context,
        'Este link foi bloqueado por motivos de segurança.',
      );
      return;
    }

    final uri = Uri.tryParse(safetyResult.normalizedUrl);
    if (uri == null) {
      AppSnackbar.error(context, 'Endereço inválido.');
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppSnackbar.error(context, 'Não foi possível abrir o navegador.');
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Erro ao abrir link: $e');
      }
    }
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: safetyResult.normalizedUrl));
    AppSnackbar.success(context, 'Link copiado para a área de transferência');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final risk = safetyResult.riskLevel;
    final isDangerous =
        risk == UrlRiskLevel.dangerous || safetyResult.isBlocked;
    final isSuspicious = risk == UrlRiskLevel.suspicious;

    final headerColor = isDangerous
        ? AppColors.error
        : (isSuspicious ? AppColors.warning : AppColors.primary);

    final titleText = isDangerous
        ? '⚠️ LINK BLOQUEADO'
        : (isSuspicious
              ? '⚠️ AVISO DE LINK SUSPEITO'
              : 'AVISO DE LINK EXTERNO');

    final badgeText = isDangerous
        ? 'PERIGOSO / NÃO PERMITIDO'
        : (isSuspicious ? 'ATENÇÃO: NÃO VERIFICADO' : 'LINK EXTERNO');

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
            // Header
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
                  tooltip: 'Fechar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Badge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  border: Border.all(color: badgeColor, width: 1),
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

            // Destination Domain Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceContainerHighest,
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DESTINO:',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    safetyResult.host,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          safetyResult.normalizedUrl,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () => _copyUrl(context),
                        tooltip: 'Copiar link',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Threat Reasons (if any)
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
                    width: 1,
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

            // Security Advice
            Text(
              isDangerous
                  ? 'Este link foi classificado como perigoso e não pode ser aberto diretamente pelo FreeBay para proteger sua conta e dispositivo.'
                  : 'Você está saindo da plataforma FreeBay. Nunca forneça suas senhas, dados de cartão ou faça pagamentos fora da nossa garantia de escrow.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                height: 1.35,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'VOLTAR COM SEGURANÇA',
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  variant: AppButtonVariant.primary,
                ),
                if (!isDangerous) ...[
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'CONTINUAR PARA O SITE EXTERNO',
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

/// Helper function to analyze and display the safe link interstitial dialog.
Future<void> showBrutalistSafeLinkDialog(
  BuildContext context,
  String rawUrl,
) async {
  final safetyResult = UrlSafetyAnalyzer.analyze(rawUrl);

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) =>
        BrutalistSafeLinkDialog(rawUrl: rawUrl, safetyResult: safetyResult),
  );
}
