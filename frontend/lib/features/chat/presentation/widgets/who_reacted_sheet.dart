import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';

class WhoReactedSheet extends StatefulWidget {
  final List<MessageReactionEntity> reactions;
  final String initialEmoji;

  const WhoReactedSheet({
    super.key,
    required this.reactions,
    required this.initialEmoji,
  });

  @override
  State<WhoReactedSheet> createState() => _WhoReactedSheetState();
}

class _WhoReactedSheetState extends State<WhoReactedSheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialEmoji;
  }

  @override
  Widget build(BuildContext context) {
    final activeReactions = widget.reactions.where((r) => r.count > 0).toList();
    final current = activeReactions.firstWhere(
      (r) => r.emoji == _selected,
      orElse: () => activeReactions.first,
    );

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji tab row
          Row(
            children: activeReactions
                .map(
                  (r) => GestureDetector(
                    onTap: () => setState(() => _selected = r.emoji),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      color: _selected == r.emoji
                          ? AppColors.surfaceContainerHighest
                          : Colors.transparent,
                      child: Text(
                        '${r.emoji} ${r.count}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          // User list — shows userIds for now; fetch display names from cache if available
          ...current.userIds.map(
            (uid) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    color: AppColors.surfaceContainerHighest,
                    child: const Icon(
                      Icons.person,
                      color: AppColors.mediumGray,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    uid,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
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
