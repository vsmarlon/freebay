import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

void showProfileStoriesSheet(BuildContext context) {
  showBrutalistSheet(
    context: context,
    title: 'Suas histórias',
    builder: (sheetContext) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                gradient: AppColors.brutalistGradient,
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(Icons.add, color: AppColors.white),
            ),
            title: Text(
              'Criar história',
              style: TextStyle(
                color: sheetContext.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text(
              'Compartilhe uma foto ou vídeo',
              style: TextStyle(color: AppColors.mediumGray),
            ),
            onTap: () {
              Navigator.pop(sheetContext);
              context.push('/create-story');
            },
          ),
          const SizedBox(height: 16),
        ],
      );
    },
  );
}
