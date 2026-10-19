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
  });

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final iconSize = compact ? 16.0 : 20.0;
    final buttonSize = compact ? 32.0 : 44.0;

    return Row(
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
              border: const OutlineInputBorder(borderSide: BorderSide.none),
              filled: true,
              fillColor: context.surfaceMidColor,
              contentPadding: padding,
              isDense: compact,
            ),
            style: TextStyle(color: context.textPrimary),
            maxLines: null,
            maxLength: 1000,
            onChanged: onChanged,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => Semantics(
                  liveRegion: true,
                  label: '$currentLength / ${maxLength ?? 1000}',
                  child: Text(
                    '$currentLength / ${maxLength ?? 1000}',
                    style: TextStyle(
                      color: currentLength >= (maxLength ?? 1000)
                          ? context.colors.error
                          : context.textSecondary,
                    ),
                  ),
                ),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
          ),
        ),
        Spacing.hSm,
        BrutalistIconButton(
          icon: Icons.send,
          semanticLabel: l10n(context).accessibilitySend,
          onTap: onSend,
          size: buttonSize,
          iconSize: iconSize,
          iconColor: AppColors.onPrimary,
          gradient: AppColors.brutalistGradient,
          isLoading: isSending,
        ),
      ],
    );
  }
}
