import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class ChatListLoadingTile extends StatelessWidget {
  final bool isDark;

  const ChatListLoadingTile({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.bgColor,
          border: Border(
            bottom: BorderSide(color: context.borderSoftColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              color: isDark
                  ? context.textSecondary.withAlpha(51)
                  : context.surfaceMidColor,
            ),
            Spacing.hMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    color: isDark
                        ? context.textSecondary.withAlpha(51)
                        : context.surfaceMidColor,
                  ),
                  Spacing.vSm,
                  Container(
                    height: 12,
                    width: 150,
                    color: isDark
                        ? context.textSecondary.withAlpha(51)
                        : context.surfaceMidColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
