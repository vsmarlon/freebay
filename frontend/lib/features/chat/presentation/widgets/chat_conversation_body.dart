import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Message area of the conversation page: skeleton, error, empty state,
/// or the scrollable message list over the optional background.
class ChatConversationBody extends StatelessWidget {
  const ChatConversationBody({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.bgUrl,
    required this.hasHeader,
    required this.loadError,
    required this.currentUserId,
    required this.otherUserName,
    required this.accentColor,
    required this.messageKeys,
    required this.highlightedMessageId,
    required this.starredIds,
    required this.isSelecting,
    required this.selectedMessageIds,
    required this.onLoadMore,
    required this.onRetry,
    required this.onToggleSelection,
    required this.onEnterSelectionMode,
    required this.onReplyTap,
    required this.onSwipeToReply,
    required this.onReactionTap,
    required this.onReactionLongPress,
    required this.onViewOnceReveal,
  });

  final ScrollController scrollController;
  final List<MessageEntity> messages;
  final String? bgUrl;
  final bool hasHeader;
  final String? loadError;
  final String? currentUserId;
  final String otherUserName;
  final Color accentColor;
  final Map<String, GlobalKey> messageKeys;
  final String? highlightedMessageId;
  final Set<String> starredIds;
  final bool isSelecting;
  final Set<String> selectedMessageIds;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onEnterSelectionMode;
  final ValueChanged<String> onReplyTap;
  final ValueChanged<MessageEntity> onSwipeToReply;
  final void Function(String msgId, String emoji) onReactionTap;
  final void Function(MessageEntity msg, String emoji) onReactionLongPress;
  final ValueChanged<String> onViewOnceReveal;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final errorMessage = loadError;
    final backgroundUrl = bgUrl;
    return Expanded(
      child: !hasHeader
          ? (errorMessage != null
                ? EmptyState.error(message: errorMessage, onRetry: onRetry)
                : const SkeletonPage(
                    child: Column(
                      children: [
                        SizedBox(height: 16),
                        ShimmerBlock(height: 60),
                        SizedBox(height: 12),
                        ShimmerBlock(height: 60),
                      ],
                    ),
                  ))
          : messages.isEmpty
          ? EmptyState(
              icon: Icons.chat_bubble_outline,
              title: strings.chatNoMessages,
              subtitle: strings.chatFirstMessage,
            )
          : Container(
              decoration: backgroundUrl != null && backgroundUrl.isNotEmpty
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          backgroundUrl,
                          headers: mediaAuthHeaders(backgroundUrl),
                        ),
                        fit: BoxFit.cover,
                        opacity: 0.15,
                      ),
                    )
                  : null,
              child: InfiniteScrollListener(
                edge: ScrollEdge.start,
                onLoadMore: onLoadMore,
                child: ChatMessageList(
                  scrollController: scrollController,
                  messages: messages,
                  currentUserId: currentUserId,
                  otherUserName: otherUserName,
                  isDark: context.isDark,
                  accentColor: accentColor,
                  messageKeys: messageKeys,
                  highlightedMessageId: highlightedMessageId,
                  starredIds: starredIds,
                  isSelecting: isSelecting,
                  selectedMessageIds: selectedMessageIds,
                  onToggleSelection: onToggleSelection,
                  onEnterSelectionMode: onEnterSelectionMode,
                  onReplyTap: onReplyTap,
                  onSwipeToReply: onSwipeToReply,
                  onReactionTap: onReactionTap,
                  onReactionLongPress: onReactionLongPress,
                  onViewOnceReveal: onViewOnceReveal,
                ),
              ),
            ),
    );
  }
}
