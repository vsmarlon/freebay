import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

class BrutalistDrawerItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? badge;

  const BrutalistDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.badge,
  });
}

class BrutalistDrawer extends StatelessWidget {
  final Widget? header;
  final List<BrutalistDrawerItem> items;
  final Widget? footer;

  const BrutalistDrawer({
    super.key,
    this.header,
    required this.items,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final headerWidget = header;
    final footerWidget = footer;

    return Drawer(
      backgroundColor: context.surfaceColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?headerWidget,
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final itemColor = item.isDestructive
                      ? AppColors.error
                      : context.textPrimary;

                  return ListTile(
                    leading: Icon(item.icon, color: itemColor, size: 22),
                    title: Text(
                      item.label.toUpperCase(),
                      style: AppTypography.brutalistTag.copyWith(
                        color: itemColor,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    trailing: item.badge,
                    onTap: item.onTap,
                  );
                },
              ),
            ),
            ?footerWidget,
          ],
        ),
      ),
    );
  }
}
