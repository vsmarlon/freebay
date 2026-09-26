import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/chat_thread_type.dart';

class ChatHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final ChatThreadType chatType;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onConfig;
  final VoidCallback? onInfo;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

  const ChatHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.chatType,
    required this.accentColor,
    required this.onBack,
    required this.onConfig,
    this.onInfo,
    this.isOnline = false,
    this.lastSeenAt,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  String get _statusLabel {
    if (isOnline) return 'Online agora';
    if (lastSeenAt != null) {
      final diff = DateTime.now().difference(lastSeenAt!);
      if (diff.inMinutes < 1) return 'Visto agora';
      if (diff.inHours < 1) return 'Visto há ${diff.inMinutes}min';
      if (diff.inDays < 1) return 'Visto há ${diff.inHours}h';
      return 'Visto há ${diff.inDays}d';
    }
    switch (chatType) {
      case ChatThreadType.order:
        return 'PEDIDO';
      case ChatThreadType.direct:
        return 'DIRETA';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: context.appBarColor,
        border: Border(bottom: BorderSide(color: accentColor, width: 2)),
      ),
      child: Row(
        children: [
          BrutalistIconButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: 12),
          UserAvatar(imageUrl: avatarUrl, size: AppAvatarSize.small),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  Container(
                    height: 16,
                    width: 140,
                    color: context.surfaceMidColor,
                  )
                else
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.italic,
                      color: context.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                if (hasError)
                  GestureDetector(
                    onTap: onRetry,
                    child: const Text(
                      'ERRO AO CARREGAR • TOCAR PARA TENTAR DE NOVO',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.error,
                      ),
                    ),
                  )
                else if (!isLoading)
                  Text(
                    _statusLabel,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isOnline
                          ? AppColors.success
                          : context.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          BrutalistIconButton(icon: Icons.info_outline, onTap: onInfo ?? () {}),
          const SizedBox(width: 4),
          BrutalistIconButton(icon: Icons.more_vert, onTap: onConfig),
        ],
      ),
    );
  }
}
