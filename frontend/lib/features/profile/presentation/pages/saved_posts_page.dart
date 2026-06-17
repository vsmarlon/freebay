import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: const Text('Salvos'),
        backgroundColor: context.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          BrutalistBreadcrumb(items: [
            BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
            const BreadcrumbItem(label: 'Salvos'),
          ]),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 80,
                    color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                  ),
                  Spacing.vLg,
                  Text(
                    'Em breve',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.white : AppColors.darkGray,
                    ),
                  ),
                  Spacing.vSm,
                  Text(
                    'Funcionalidade em desenvolvimento',
                    style: TextStyle(
                      color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
