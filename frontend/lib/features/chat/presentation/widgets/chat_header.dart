import 'package:flutter/material.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';

class ChatHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String chatType;
  final Color accentColor;
  final VoidCallback onBack;
  final VoidCallback onConfig;

  const ChatHeader({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.chatType,
    required this.accentColor,
    required this.onBack,
    required this.onConfig,
  });

  String get _statusLabel {
    switch (chatType) {
      case 'order':
        return 'PEDIDO';
      case 'direct':
        return 'DIRETA';
      default:
        return chatType.toUpperCase();
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
        border: Border(
          bottom: BorderSide(color: accentColor, width: 2),
        ),
      ),
      child: Row(
        children: [
          BrutalistIconButton(icon: Icons.arrow_back, onTap: onBack),
          const SizedBox(width: 12),
          UserAvatar(
            imageUrl: avatarUrl,
            size: AppAvatarSize.small,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                Text(
                  _statusLabel,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          BrutalistIconButton(icon: Icons.more_vert, onTap: onConfig),
        ],
      ),
    );
  }
}
