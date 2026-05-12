import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_colors.dart';
import '../theme/theme_extension.dart';

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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size.value,
          height: size.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.surfaceMidColor,
            border: Border.all(
              color: isVerified
                  ? AppColors.primaryPurple
                  : AppColors.mediumGray.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildPlaceholder(),
                    errorWidget: (context, url, error) =>
                        _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified,
                color: AppColors.primaryPurple,
                size: size == AppAvatarSize.small ? 12 : 16,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Icon(Icons.person,
        color: AppColors.mediumGray,
        size: size.value * 0.5);
  }
}
