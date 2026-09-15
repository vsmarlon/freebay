import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';

class CreateComposerSheet extends StatelessWidget {
  const CreateComposerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CreateComposerOption(
          icon: Icons.forum_outlined,
          title: 'Post social',
          subtitle: 'Publicações, opiniões e interações para o feed.',
          onTap: () {
            Navigator.of(context).pop();
            context.push(AppRoutes.createPost);
          },
        ),
        _CreateComposerOption(
          icon: Icons.sell_outlined,
          title: 'Anúncio de venda',
          subtitle: 'Item para catálogo com preço, categoria e imagem.',
          onTap: () {
            Navigator.of(context).pop();
            context.push(AppRoutes.createProduct);
          },
        ),
      ],
    );
  }
}

class _CreateComposerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateComposerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.all(16),
        color: context.surfaceMidColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              color: AppColors.primaryContainer,
              child: Icon(icon, color: AppColors.onPrimary),
            ),
            Spacing.hSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.vXs,
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Spacing.hSm,
            const Icon(Icons.arrow_forward, color: AppColors.primaryContainer),
          ],
        ),
      ),
    );
  }
}
