import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_reaction_entity.dart';
import 'package:freebay/shared/services/http_client.dart';

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
  final Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _selected = widget.initialEmoji;
    _fetchNames();
  }

  Future<void> _fetchNames() async {
    final allUserIds = widget.reactions.expand((r) => r.userIds).toSet();
    for (final uid in allUserIds) {
      if (!_userNames.containsKey(uid)) {
        try {
          final res = await HttpClient.instance.get('/users/$uid');
          if (res.statusCode == 200) {
            final data = res.data['data'] as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _userNames[uid] = data['displayName'] ?? uid;
              });
            }
          }
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeReactions = widget.reactions.where((r) => r.count > 0).toList();
    final current = activeReactions.firstWhere(
      (r) => r.emoji == _selected,
      orElse: () => activeReactions.first,
    );

    return Column(
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
        // User list
        ...current.userIds.map(
          (uid) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  color: AppColors.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    color: context.textSecondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _userNames[uid] ?? 'Carregando...',
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
