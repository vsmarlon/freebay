import 'package:flutter/material.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_header.dart';
import 'package:freebay/features/chat/presentation/widgets/multi_select_toolbar.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';

/// Header switch for the conversation page: selection toolbar, error,
/// loading, or the loaded chat header. Pure function of its inputs.
class ChatConversationHeader extends StatelessWidget {
  const ChatConversationHeader({
    super.key,
    required this.isSelecting,
    required this.selectedCount,
    required this.hasHeader,
    required this.loadError,
    required this.name,
    this.avatarUrl,
    required this.chatType,
    required this.accentColor,
    required this.isOnline,
    required this.onBack,
    required this.onConfig,
    required this.onInfo,
    required this.onRetry,
    required this.onCloseSelection,
    required this.onCopy,
    required this.onForward,
    required this.onDelete,
    required this.onReply,
    required this.onStar,
    required this.onShare,
  });

  final bool isSelecting;
  final int selectedCount;
  final bool hasHeader;
  final String? loadError;
  final String name;
  final String? avatarUrl;
  final ChatThreadType chatType;
  final Color accentColor;
  final bool isOnline;
  final VoidCallback onBack;
  final VoidCallback onConfig;
  final VoidCallback onInfo;
  final VoidCallback onRetry;
  final VoidCallback onCloseSelection;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onDelete;
  final VoidCallback onReply;
  final VoidCallback onStar;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    if (isSelecting) {
      return MultiSelectToolbar(
        selectedCount: selectedCount,
        onClose: onCloseSelection,
        onCopy: onCopy,
        onForward: onForward,
        onDelete: onDelete,
        onReply: onReply,
        onStar: onStar,
        onShare: onShare,
      );
    }
    if (loadError != null && !hasHeader) {
      return ChatHeader(
        name: '',
        chatType: ChatThreadType.direct,
        accentColor: accentColor,
        hasError: true,
        onBack: onBack,
        onConfig: onConfig,
        onRetry: onRetry,
      );
    }
    if (!hasHeader) {
      return ChatHeader(
        name: '',
        chatType: ChatThreadType.direct,
        accentColor: accentColor,
        isLoading: true,
        onBack: onBack,
        onConfig: onConfig,
      );
    }
    return ChatHeader(
      name: name,
      avatarUrl: avatarUrl,
      chatType: chatType,
      accentColor: accentColor,
      isOnline: isOnline,
      onBack: onBack,
      onConfig: onConfig,
      onInfo: onInfo,
    );
  }
}
