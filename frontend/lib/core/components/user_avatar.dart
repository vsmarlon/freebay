import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/theme/app_colors.dart';

enum AppAvatarSize {
  small(32),
  medium(48),
  large(80);

  final double value;
  const AppAvatarSize(this.value);
}

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final bool isVerified;
  final AppAvatarSize size;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.isVerified = false,
    this.size = AppAvatarSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isVerified
        ? AppColors.primaryContainer
        : AppColors.onSurface.withValues(alpha: 0.15);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.value,
          height: size.value,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPlaceholder(),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                borderRadius: BorderRadius.zero,
                border: Border.all(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.verified,
                color: AppColors.primaryContainer,
                size: size == AppAvatarSize.small ? 12 : 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Icon(
      Icons.person,
      color: AppColors.onSurfaceVariant,
      size: size.value * 0.5,
    );
  }
}
