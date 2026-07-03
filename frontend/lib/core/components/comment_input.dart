import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/components/spacing.dart';

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool isSending;
  final VoidCallback onSend;
  final String hint;
  final bool compact;

  const CommentInput({
    super.key,
    required this.controller,
    this.focusNode,
    required this.isSending,
    required this.onSend,
    this.hint = 'Adicionar comentário...',
    this.compact = false,
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
        if (compact) const SizedBox(width: 40),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.mediumGray),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: context.surfaceMidColor,
              contentPadding: padding,
              isDense: compact,
            ),
            style: TextStyle(color: context.textPrimary),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
          ),
        ),
        Spacing.hSm,
        BrutalistIconButton(
          icon: Icons.send,
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
