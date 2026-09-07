import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/view_once_toggle.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool viewOnceEnabled;
  final Color accentColor;
  final VoidCallback onSend;
  final VoidCallback onAttachment;
  final ValueChanged<bool> onViewOnceToggled;
  final VoidCallback? onRecordAudio;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.viewOnceEnabled,
    required this.accentColor,
    required this.onSend,
    required this.onAttachment,
    required this.onViewOnceToggled,
    this.onRecordAudio,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          BrutalistIconButton(
            icon: Icons.add,
            onTap: widget.onAttachment,
            size: 48,
            iconSize: 24,
            iconColor: context.textPrimary,
            borderColor: context.borderColor,
          ),
          Spacing.hSm,
          ViewOnceToggle(
            enabled: widget.viewOnceEnabled,
            onTap: () => widget.onViewOnceToggled(!widget.viewOnceEnabled),
          ),
          Spacing.hSm,
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.isDark
                    ? Colors.white.withAlpha(13)
                    : Colors.black.withAlpha(13),
                border: Border.all(color: context.borderColor, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        color: context.textPrimary,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Digite uma mensagem...',
                        hintStyle: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (widget.isSending)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.accentColor,
                        ),
                      ),
                    )
                  else if (_hasText)
                    IconButton(
                      icon: Icon(Icons.send, color: widget.accentColor),
                      onPressed: widget.onSend,
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.mic, color: widget.accentColor),
                      onPressed: widget.onRecordAudio ?? widget.onSend,
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
