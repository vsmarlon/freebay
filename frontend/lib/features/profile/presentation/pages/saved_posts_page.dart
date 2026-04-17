import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Salvos'),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 80,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
            const SizedBox(height: 24),
            Text(
              'Em breve',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Funcionalidade em desenvolvimento',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
