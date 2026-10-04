import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/conversation_media_filter.dart';
import 'package:freebay/features/chat/presentation/widgets/link_preview_card.dart';
import 'package:freebay/features/chat/presentation/widgets/media_grid.dart';
import 'package:freebay/shared/utils/date_utils.dart';

class ConversationDetailsHeader extends StatelessWidget {
  final String? name;
  final String? avatarUrl;

  const ConversationDetailsHeader({super.key, this.name, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (name == null) {
      return const ShimmerScope(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: ShimmerBlock(width: 160, height: 24),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.borderColor, width: 2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.textSecondary,
              border: Border.all(color: context.borderColor, width: 2),
              image: avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: avatarUrl == null
                ? const Icon(Icons.person, size: 36, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name!,
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: context.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class ConversationDetailsMediaTab extends StatelessWidget {
  final String conversationId;
  final List<MessageEntity> messages;
  final ConversationMediaFilter filter;
  final ValueChanged<ConversationMediaFilter> onFilterChanged;
  final Future<List<MessageEntity>> Function(String? cursor) onLoadMore;

  const ConversationDetailsMediaTab({
    super.key,
    required this.conversationId,
    required this.messages,
    required this.filter,
    required this.onFilterChanged,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final type in ConversationMediaFilter.values)
              FilterChip(
                label: Text(type.wireValue),
                selected: filter == type,
                onSelected: (_) => onFilterChanged(type),
              ),
          ],
        ),
        Expanded(
          child: filter == ConversationMediaFilter.link
              ? ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    for (final message in messages)
                      LinkPreviewCard(metadata: message.metadata),
                  ],
                )
              : MediaGrid(
                  conversationId: conversationId,
                  initialMessages: messages,
                  onLoadMore: onLoadMore,
                ),
        ),
      ],
    );
  }
}

class ConversationDetailsStarredTab extends StatelessWidget {
  final List<MessageEntity> messages;
  final Set<String> starredIds;
  final ValueChanged<String> onOpen;
  final ValueChanged<String> onUnstar;

  const ConversationDetailsStarredTab({
    super.key,
    required this.messages,
    required this.starredIds,
    required this.onOpen,
    required this.onUnstar,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final starred = messages.where((m) => starredIds.contains(m.id)).toList();
    if (starred.isEmpty) {
      return EmptyState(
        icon: Icons.star_outline,
        title: strings.chatNoFavorites,
        subtitle: strings.chatFavoriteHint,
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: starred.length,
      itemBuilder: (context, index) {
        final message = starred[index];
        return InkWell(
          onTap: () => onOpen(message.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.previewText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${localizedShortDate(context, message.createdAt)} ${formatMessageTime(message.createdAt)}',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 11,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                BrutalistIconButton(
                  icon: Icons.star,
                  semanticLabel: strings.chatRemoveStarred,
                  iconColor: AppColors.primaryContainer,
                  onTap: () => onUnstar(message.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConversationDetailsActionsTab extends StatelessWidget {
  final bool isMuted;
  final VoidCallback onToggleMute;
  final VoidCallback onTheme;
  final VoidCallback onBlock;
  final VoidCallback onDelete;

  const ConversationDetailsActionsTab({
    super.key,
    required this.isMuted,
    required this.onToggleMute,
    required this.onTheme,
    required this.onBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Column(
      children: [
        _ActionTile(
          icon: isMuted ? Icons.volume_up : Icons.volume_off,
          title: isMuted
              ? strings.chatNotificationsEnabled
              : strings.chatNotificationsMuted,
          onTap: onToggleMute,
        ),
        _ActionTile(
          icon: Icons.color_lens,
          title: strings.chatConversationTheme,
          onTap: onTheme,
        ),
        _ActionTile(
          icon: Icons.block,
          title: strings.chatBlockUser,
          isDestructive: true,
          onTap: onBlock,
        ),
        _ActionTile(
          icon: Icons.delete_sweep,
          title: strings.chatDeleteConversation,
          isDestructive: true,
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : context.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.borderColor)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: context.textSecondary),
          ],
        ),
      ),
    );
  }
}
