import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'POSTS SALVOS',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            breadcrumbs: context.breadcrumbs,
          ),
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
                      color: isDark
                          ? AppColors.mediumGray
                          : AppColors.mediumGray,
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
