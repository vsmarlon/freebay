import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';

class ReactionBar extends StatelessWidget {
  final List<MessageReactionEntity> reactions;
  final ValueChanged<String>? onReactionTap;
  final void Function(String emoji, LongPressStartDetails details)?
  onReactionLongPress;

  const ReactionBar({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.onReactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactions.map((reaction) {
          return GestureDetector(
            onTap: () => onReactionTap?.call(reaction.emoji),
            onLongPressStart: (details) =>
                onReactionLongPress?.call(reaction.emoji, details),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainerHigh,
                border: Border.all(color: AppColors.outlineVariant, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(reaction.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    '${reaction.count}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
