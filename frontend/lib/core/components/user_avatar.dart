import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.value,
          height: size.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? AppColors.surfaceDark : AppColors.lightGray,
            border: Border.all(
              color: isVerified
                  ? (isDark
                      ? AppColors.primaryPurpleLight
                      : AppColors.primaryPurple)
                  : AppColors.mediumGray.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(isDark),
                    errorWidget: (context, url, error) =>
                        _buildPlaceholder(isDark),
                  )
                : _buildPlaceholder(isDark),
          ),
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: isDark
                    ? AppColors.primaryPurpleLight
                    : AppColors.primaryPurple,
                size: size == AppAvatarSize.small ? 12 : 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Icon(Icons.person,
        color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
        size: size.value * 0.5);
  }
}
