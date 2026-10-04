import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/components/blur_hash_placeholder.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

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
  final double? dimension;
  final String? heroTag;
  final String? blurHash;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.isVerified = false,
    this.size = AppAvatarSize.medium,
    this.dimension,
    this.heroTag,
    this.blurHash,
  });

  @override
  Widget build(BuildContext context) {
    final avatarDimension = dimension ?? size.value;
    final borderColor = isVerified
        ? AppColors.primaryContainer
        : AppColors.onSurface.withValues(alpha: 0.15);
    final image = imageUrl != null && imageUrl!.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            memCacheWidth: (avatarDimension * 2.5).toInt(),
            memCacheHeight: (avatarDimension * 2.5).toInt(),
            placeholder: (context, url) => _buildBlurHashPlaceholder(),
            errorWidget: (context, url, error) => _buildPlaceholder(),
          )
        : _buildPlaceholder();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: avatarDimension,
          height: avatarDimension,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            border: Border.all(color: borderColor, width: 2),
          ),
          child: _hero(image),
        ),
        if (isVerified)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.onPrimary,
                border: Border.all(color: AppColors.primaryContainer, width: 2),
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

  Widget _hero(Widget child) =>
      heroTag == null ? child : Hero(tag: heroTag!, child: child);

  Widget _buildPlaceholder() {
    return Icon(
      Icons.person,
      color: AppColors.onSurfaceVariant,
      size: (dimension ?? size.value) * 0.5,
    );
  }

  Widget _buildBlurHashPlaceholder() =>
      BlurHashPlaceholder(hash: blurHash, fallback: _buildPlaceholder());
}
