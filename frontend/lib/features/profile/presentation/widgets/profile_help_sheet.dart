import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';

/// "Ajuda e suporte" sheet. Owns the help content so the settings sheet
/// stays a pure list of rows.
void showProfileHelpSheet({
  required BuildContext context,
  required GoRouter router,
}) {
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  showBrutalistSheet(
    context: rootNavigator.context,
    title: 'Ajuda e suporte',
    builder: (sheetContext) {
      return Consumer(
        builder: (consumerContext, consumerRef, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Em caso de dúvidas ou problemas, acesse o centro de ajuda:',
                  style: TextStyle(
                    fontSize: 14,
                    color: consumerContext.textSecondary,
                  ),
                ),
                Spacing.vLg,
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Central de ajuda',
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (rootNavigator.mounted) {
                          router.push(AppRoutes.faq);
                        }
                      });
                    },
                  ),
                ),
                Spacing.vSm,
                InkWell(
                  onTap: () => Navigator.pop(sheetContext),
                  child: Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.onSurface, width: 2),
                    ),
                    child: const Center(
                      child: Text(
                        'Fechar',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
