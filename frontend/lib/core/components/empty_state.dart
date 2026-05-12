import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  factory EmptyState.noPosts({
    Key? key,
    String? subtitle,
    Widget? action,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.explore_outlined,
      title: 'NENHUM POST AINDA',
      subtitle: subtitle ?? 'Siga usuários ou crie seu primeiro post!',
      action: action,
    );
  }

  factory EmptyState.noResults({
    Key? key,
    String? subtitle,
    Widget? action,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.search_off,
      title: 'NENHUM RESULTADO',
      subtitle: subtitle,
      action: action,
    );
  }

  factory EmptyState.error({
    Key? key,
    String? message,
    VoidCallback? onRetry,
  }) {
    return EmptyState(
      key: key,
      icon: Icons.error_outline,
      title: 'ERRO AO CARREGAR',
      subtitle: message,
      action: onRetry != null
          ? TextButton(
              onPressed: onRetry,
              child: const Text(
                'TENTAR NOVAMENTE',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryContainer,
                ),
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.surfaceMidColor,
                border: Border.all(
                  color: AppColors.outline,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 40,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}