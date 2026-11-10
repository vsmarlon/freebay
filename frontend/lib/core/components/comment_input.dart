import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final String? hint;
  final bool compact;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onDiscard;
  final Widget? suggestions;

  const CommentInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isSending,
    required this.onSend,
    this.hint,
    this.compact = false,
    this.onChanged,
    this.onDiscard,
    this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final iconSize = compact ? 16.0 : 20.0;
    final buttonSize = compact ? 32.0 : 44.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final count = value.text.characters.length;
            final withinLimit = count <= 280;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    if (onDiscard != null)
                      BrutalistIconButton(
                        icon: Icons.close,
                        semanticLabel: l10n(context).commonClear,
                        onTap: onDiscard,
                        size: buttonSize,
                        iconSize: iconSize,
                      ),
                    if (compact) const SizedBox(width: 40),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: hint ?? l10n(context).feedReplyingHint,
                          hintStyle: TextStyle(color: context.textSecondary),
                          border: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.zero,
                          ),
                          filled: true,
                          fillColor: context.surfaceMidColor,
                          contentPadding: padding,
                          isDense: compact,
                        ),
                        style: TextStyle(color: context.textPrimary),
                        maxLines: null,
                        onChanged: onChanged,
                        buildCounter:
                            (
                              _, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) => null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendIfValid(),
                      ),
                    ),
                    Spacing.hSm,
                    BrutalistIconButton(
                      icon: Icons.send,
                      semanticLabel: l10n(context).accessibilitySend,
                      onTap:
                          withinLimit &&
                              value.text.trim().isNotEmpty &&
                              !isSending
                          ? _sendIfValid
                          : null,
                      size: buttonSize,
                      iconSize: iconSize,
                      iconColor: AppColors.onPrimary,
                      gradient: AppColors.brutalistGradient,
                      isLoading: isSending,
                    ),
                  ],
                ),
                Visibility(
                  visible: count >= 260,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Semantics(
                    liveRegion: true,
                    label: '$count / 280',
                    child: Text(
                      '$count / 280',
                      style: AppTypography.bodySmall.copyWith(
                        color: count > 280
                            ? context.colors.error
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        ?suggestions,
      ],
    );
  }

  void _sendIfValid() {
    final length = controller.text.characters.length;
    if (!isSending && controller.text.trim().isNotEmpty && length <= 280) {
      onSend();
    }
  }
}
