import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class CreateComposerSheet extends StatelessWidget {
  const CreateComposerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BrutalistSheetScaffold(
      title: 'O QUE VOCE QUER CRIAR?',
      showDragHandle: false,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CreateComposerOption(
            icon: Icons.forum_outlined,
            title: 'Post social',
            subtitle: 'Publicacoes, opinioes e interacoes para o feed.',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/create-post');
            },
          ),
          _CreateComposerOption(
            icon: Icons.sell_outlined,
            title: 'Anuncio de venda',
            subtitle: 'Item para catalogo com preco, categoria e imagem.',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/create-product');
            },
          ),
        ],
      ),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, color: AppColors.primaryContainer),
          ],
        ),
      ),
    );
  }
}
