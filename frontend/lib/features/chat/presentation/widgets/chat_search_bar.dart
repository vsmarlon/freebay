import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ChatSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool hasQuery;
  final VoidCallback onClear;
  final VoidCallback onArchiveTap;
  final VoidCallback onNewChatTap;
  final bool isDark;

  const ChatSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.hasQuery,
    required this.onClear,
    required this.onArchiveTap,
    required this.onNewChatTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.bgColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: strings.chatSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: onClear,
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? AppColors.backgroundDark
                    : context.surfaceMidColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: context.borderSoftColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Spacing.hSm,
          BrutalistIconButton(
            icon: Icons.archive,
            semanticLabel: strings.chatArchivedTitle,
            size: 48,
            onTap: onArchiveTap,
          ),
          Spacing.hSm,
          BrutalistIconButton(
            icon: Icons.edit,
            semanticLabel: strings.chatNewConversation,
            size: 48,
            iconColor: AppColors.onPrimary,
            gradient: AppColors.brutalistGradient,
            onTap: onNewChatTap,
          ),
        ],
      ),
    );
  }
}
