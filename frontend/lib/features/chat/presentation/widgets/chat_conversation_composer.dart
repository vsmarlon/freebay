import 'package:flutter/material.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/presentation/widgets/audio_recorder_bar.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:freebay/features/chat/presentation/widgets/reply_composer_banner.dart';
import 'package:freebay/features/chat/presentation/widgets/typing_indicator_bubble.dart';

/// Input area of the conversation page: typing indicator, reply banner,
///
/// audio recorder or text bar. Pure function of its inputs.
class ChatConversationComposer extends StatelessWidget {
  const ChatConversationComposer({
    super.key,
    required this.otherUserTyping,
    required this.replyTarget,
    required this.currentUserId,
    required this.otherUserName,
    required this.accentColor,
    required this.isRecording,
    required this.messageController,
    required this.isSending,
    required this.viewOnceEnabled,
    required this.onCancelReply,
    required this.onSendAudio,
    required this.onCancelRecording,
    required this.onSend,
    required this.onRecordAudio,
    required this.onAttachment,
    required this.onViewOnceToggled,
  });

  final bool otherUserTyping;
  final MessageEntity? replyTarget;
  final String? currentUserId;
  final String? otherUserName;
  final Color accentColor;
  final bool isRecording;
  final TextEditingController messageController;
  final bool isSending;
  final bool viewOnceEnabled;
  final VoidCallback onCancelReply;
  final ValueChanged<AudioRecording> onSendAudio;
  final VoidCallback onCancelRecording;
  final VoidCallback onSend;
  final VoidCallback onRecordAudio;
  final VoidCallback onAttachment;
  final ValueChanged<bool> onViewOnceToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (otherUserTyping) const TypingIndicatorBubble(),
        if (replyTarget != null && otherUserName != null)
          ReplyComposerBanner(
            replyTo: replyTarget!,
            currentUserId: currentUserId,
            otherUserName: otherUserName ?? '',
            accentColor: accentColor,
            onCancel: onCancelReply,
          ),
        if (isRecording)
          AudioRecorderBar(onSend: onSendAudio, onCancel: onCancelRecording)
        else
          ChatInputBar(
            controller: messageController,
            isSending: isSending,
            viewOnceEnabled: viewOnceEnabled,
            accentColor: accentColor,
            onSend: onSend,
            onRecordAudio: onRecordAudio,
            onAttachment: onAttachment,
            onViewOnceToggled: onViewOnceToggled,
          ),
      ],
    );
  }
}
