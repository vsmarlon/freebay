import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class FeedDrawerFooter extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback onReportBug;

  const FeedDrawerFooter({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.onSettings,
    required this.onLogout,
    required this.onReportBug,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceMidColor,
        border: Border(
          top: BorderSide(color: context.borderColor.withAlpha(50), width: 1.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.textPrimary,
            ),
            tooltip: isDark ? 'Modo claro' : 'Modo escuro',
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: Icon(Icons.bug_report_outlined, color: context.textSecondary),
            tooltip: 'Reportar problema',
            onPressed: onReportBug,
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textSecondary),
            tooltip: 'Configurações',
            onPressed: onSettings,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            tooltip: 'Sair',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}
