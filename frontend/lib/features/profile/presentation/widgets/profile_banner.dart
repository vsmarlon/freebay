import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class ProfileBanner extends StatelessWidget {
  const ProfileBanner({
    super.key,
    required this.user,
    required this.isOwnProfile,
    required this.onUpload,
    required this.avatar,
  });

  final UserEntity user;
  final bool isOwnProfile;
  final VoidCallback onUpload;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: context.borderColor, width: 2),
            color: context.surfaceColor,
            image: user.bannerUrl != null
                ? DecorationImage(
                    image: NetworkImage(user.bannerUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
            gradient: user.bannerUrl == null
                ? AppColors.brutalistGradient
                : null,
          ),
          child: isOwnProfile
              ? Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: onUpload,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                )
              : null,
        ),
        Positioned(
          left: 16,
          bottom: -40,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor, width: 3),
              color: context.bgColor,
            ),
            child: avatar,
          ),
        ),
      ],
    );
  }
}
