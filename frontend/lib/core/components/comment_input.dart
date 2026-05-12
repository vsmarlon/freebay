import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';

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
    final padding =
        compact ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8) : const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
    final iconSize = compact ? 16.0 : 20.0;
    final containerPadding = compact ? const EdgeInsets.all(8.0) : const EdgeInsets.all(12.0);

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
        const SizedBox(width: 8),
        GestureDetector(
          onTap: isSending ? null : onSend,
          child: Container(
            padding: containerPadding,
            decoration: const BoxDecoration(
              gradient: AppColors.brutalistGradient,
            ),
            child: isSending
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.send, color: Colors.white, size: iconSize),
          ),
        ),
      ],
    );
  }
}
