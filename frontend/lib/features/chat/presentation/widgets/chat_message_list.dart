import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/message_bubble.dart';
import 'package:freebay/features/chat/presentation/widgets/date_separator.dart';
import 'package:freebay/core/utils/date_utils.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_media_gallery_viewer.dart';

class ChatMessageList extends StatelessWidget {
  final ScrollController scrollController;
  final List<MessageEntity> messages;
  final String? currentUserId;
  final String otherUserName;
  final bool isDark;
  final Color accentColor;
  final Map<String, GlobalKey> messageKeys;
  final String? highlightedMessageId;
  final double replyHighlightAlpha;
  final Set<String> starredIds;

  // Selection
  final bool isSelecting;
  final Set<String> selectedMessageIds;
  final ValueChanged<String> onToggleSelection;
  final ValueChanged<String> onEnterSelectionMode;

  // Actions
  final ValueChanged<String> onReplyTap;
  final ValueChanged<MessageEntity> onSwipeToReply;
  final void Function(String, String) onReactionTap;
  final void Function(MessageEntity, String) onReactionLongPress;
  final ValueChanged<String> onViewOnceReveal;

  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.currentUserId,
    required this.otherUserName,
    required this.isDark,
    required this.accentColor,
    required this.messageKeys,
    required this.highlightedMessageId,
    this.replyHighlightAlpha = 0.18,
    this.starredIds = const {},
    required this.isSelecting,
    required this.selectedMessageIds,
    required this.onToggleSelection,
    required this.onEnterSelectionMode,
    required this.onReplyTap,
    required this.onSwipeToReply,
    required this.onReactionTap,
    required this.onReactionLongPress,
    required this.onViewOnceReveal,
  });

  bool _isSameSender(int index) {
    final current = messages[index].senderId;
    final next = index + 1 < messages.length
        ? messages[index + 1].senderId
        : null;
    return current == next;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: false,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msgEntity = messages[index];
        final isMe = msgEntity.senderId == currentUserId;
        final prevIsMe = index > 0
            ? messages[index - 1].senderId == currentUserId
            : false;
        final isConsecutive = isMe == prevIsMe;
        final messageKey = messageKeys[msgEntity.id];

        // Date separator when day changes
        final showDateSep =
            index == 0 ||
            !isSameDay(msgEntity.createdAt, messages[index - 1].createdAt);

        // Show timestamp on last msg of group
        final isLastMsg = index == messages.length - 1;
        final showTime = isLastMsg || !_isSameSender(index);

        return RepaintBoundary(
          key: ValueKey('msg_${msgEntity.id}'),
          child: Column(
            children: [
              if (showDateSep) DateSeparator(date: msgEntity.createdAt),
              Container(
                key: messageKey,
                color: highlightedMessageId == msgEntity.id
                    ? accentColor.withValues(alpha: replyHighlightAlpha)
                    : null,
                child: GestureDetector(
                  onTap: isSelecting
                      ? () => onToggleSelection(msgEntity.id)
                      : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    children: [
                      if (!isMe)
                        AnimatedContainer(
                          duration: AppMotion.base,
                          width: isSelecting ? 36 : 0,
                          alignment: Alignment.centerLeft,
                          child: ClipRect(
                            child: IgnorePointer(
                              child: Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 8, right: 8),
                                decoration: BoxDecoration(
                                  color:
                                      selectedMessageIds.contains(msgEntity.id)
                                      ? AppColors.primaryContainer
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: AppColors.primaryContainer,
                                    width: 2,
                                  ),
                                ),
                                child: selectedMessageIds.contains(msgEntity.id)
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.onPrimary,
                                        size: 12,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      Flexible(
                        child: MessageBubble(
                          message: msgEntity,
                          isMe: isMe,
                          isDark: isDark,
                          isConsecutive: isConsecutive,
                          showTimestamp: showTime,
                          accentColor: accentColor,
                          isStarred: starredIds.contains(msgEntity.id),
                          currentUserId: currentUserId,
                          otherUserName: otherUserName,
                          onReplyTap:
                              !isSelecting && msgEntity.replyToId != null
                              ? () => onReplyTap(msgEntity.replyToId!)
                              : null,
                          onLongPressMessage: isSelecting
                              ? null
                              : () {
                                  HapticFeedback.mediumImpact();
                                  onEnterSelectionMode(msgEntity.id);
                                },
                          onSwipeToReply: () => onSwipeToReply(msgEntity),
                          onReactionTap: isSelecting
                              ? null
                              : (emoji) => onReactionTap(msgEntity.id, emoji),
                          onReactionLongPress: isSelecting
                              ? null
                              : (emoji, details) =>
                                    onReactionLongPress(msgEntity, emoji),
                          onViewOnceReveal:
                              !isSelecting &&
                                  msgEntity.viewOnce &&
                                  msgEntity.readAt == null
                              ? () => onViewOnceReveal(msgEntity.id)
                              : null,
                          onImageTap:
                              (msgEntity.type == MessageType.image ||
                                  msgEntity.type == MessageType.gif ||
                                  msgEntity.type == MessageType.video)
                              ? () {
                                  final allMedia =
                                      ChatMediaGalleryViewer.extractMedia(
                                        messages,
                                      );
                                  final mediaIndex = allMedia.indexWhere(
                                    (m) => m.id == msgEntity.id,
                                  );
                                  if (mediaIndex < 0) return;
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      barrierColor: Colors.black,
                                      transitionDuration: AppMotion.enter,
                                      reverseTransitionDuration:
                                          AppMotion.enter,
                                      transitionsBuilder: (_, a, _, c) =>
                                          FadeTransition(opacity: a, child: c),
                                      pageBuilder: (_, _, _) =>
                                          ChatMediaGalleryViewer(
                                            mediaMessages: allMedia,
                                            initialIndex: mediaIndex,
                                          ),
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),
                      if (isMe)
                        AnimatedContainer(
                          duration: AppMotion.base,
                          width: isSelecting ? 36 : 0,
                          alignment: Alignment.centerRight,
                          child: ClipRect(
                            child: IgnorePointer(
                              child: Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 8, left: 8),
                                decoration: BoxDecoration(
                                  color:
                                      selectedMessageIds.contains(msgEntity.id)
                                      ? AppColors.primaryContainer
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: AppColors.primaryContainer,
                                    width: 2,
                                  ),
                                ),
                                child: selectedMessageIds.contains(msgEntity.id)
                                    ? const Icon(
                                        Icons.check,
                                        color: AppColors.onPrimary,
                                        size: 12,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
