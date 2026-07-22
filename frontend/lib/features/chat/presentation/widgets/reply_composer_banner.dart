import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';

class ReplyComposerBanner extends StatelessWidget {
  final MessageEntity replyTo;
  final String senderLabel;
  final Color accentColor;
  final VoidCallback onCancel;

  const ReplyComposerBanner({
    super.key,
    required this.replyTo,
    required this.senderLabel,
    required this.accentColor,
    required this.onCancel,
  });

  String get _previewText {
    final content = replyTo.content ?? '';
    if (content.isNotEmpty) return content;
    final type = replyTo.type.toUpperCase();
    if (type == 'IMAGE' || type == 'GIF') return 'Imagem';
    if (type == 'LOCATION') return 'Localização';
    if (type == 'PRODUCT_CARD') return 'Produto';
    return 'Mensagem';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerHigh,
        border: Border(top: BorderSide(color: accentColor, width: 2)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: accentColor),
          Spacing.hSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  senderLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _previewText,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12,
                    color: context.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            color: context.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
