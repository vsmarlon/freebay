import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/view_once_toggle.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool viewOnceEnabled;
  final Color accentColor;
  final VoidCallback onSend;
  final void Function({bool camera}) onAttachment;
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
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: Tooltip(
              message: strings.accessibilityAttach,
              child: BrutalistIconButton(
                icon: Icons.add,
                semanticLabel: strings.accessibilityAttach,
                onTap: widget.onAttachment,
                size: 48,
                iconSize: 24,
                iconColor: context.textPrimary,
                borderColor: context.borderColor,
              ),
            ),
          ),
          Spacing.hSm,
          Tooltip(
            message: strings.accessibilityCamera,
            child: BrutalistIconButton(
              icon: Icons.camera_alt_outlined,
              semanticLabel: strings.accessibilityCamera,
              onTap: () => widget.onAttachment(camera: true),
              size: 48,
              iconSize: 24,
              iconColor: context.textPrimary,
              borderColor: context.borderColor,
            ),
          ),
          Spacing.hSm,
          Expanded(
            child: KeyedSubtree(
              key: const ValueKey('chat-input-surface'),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 48,
                  maxHeight: MediaQuery.textScalerOf(
                    context,
                  ).scale(72).clamp(72.0, 144.0),
                ),
                decoration: BoxDecoration(
                  color: context.surfaceHighColor,
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        minLines: 1,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: context.textPrimary,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: strings.chatMessageHint,
                          hintMaxLines: 1,
                          hintStyle: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 14,
                            color: context.textSecondary,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    ViewOnceToggle(
                      enabled: widget.viewOnceEnabled,
                      semanticLabel: strings.chatViewOnce,
                      onTap: () =>
                          widget.onViewOnceToggled(!widget.viewOnceEnabled),
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
                      BrutalistIconButton(
                        icon: Icons.send,
                        semanticLabel: strings.accessibilitySend,
                        size: 48,
                        iconColor: widget.accentColor,
                        onTap: widget.onSend,
                      )
                    else
                      BrutalistIconButton(
                        icon: Icons.mic,
                        semanticLabel: strings.chatSendAudio,
                        size: 48,
                        iconColor: widget.accentColor,
                        onTap: widget.onRecordAudio ?? widget.onSend,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
