import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';

class ReplyPreviewBanner extends StatelessWidget {
  final MessageEntity? replyTo;
  final String? currentUserId;
  final String? otherUserName;
  final VoidCallback? onTap;

  const ReplyPreviewBanner({
    super.key,
    this.replyTo,
    this.currentUserId,
    this.otherUserName,
    this.onTap,
  });

  String get _senderLabel {
    if (replyTo == null) return '';
    if (currentUserId != null && replyTo!.senderId == currentUserId) {
      return 'Você';
    }
    return otherUserName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDeleted = replyTo == null;
    final displayText = isDeleted
        ? 'Mensagem apagada'
        : (replyTo!.content ?? '').isNotEmpty
        ? replyTo!.content!
        : (replyTo!.type == 'IMAGE' || replyTo!.type == 'GIF')
        ? 'Imagem'
        : (replyTo!.type == 'LOCATION')
        ? 'Localização'
        : 'Mensagem';

    final banner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.isDark
            ? AppColors.surfaceContainerDark
            : AppColors.surfaceContainerHigh,
        border: const Border(
          left: BorderSide(color: AppColors.primaryContainer, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _senderLabel,
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryContainer,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            displayText,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
              color: context.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap == null) return banner;
    return InkWell(onTap: onTap, child: banner);
  }
}
