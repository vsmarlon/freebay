import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';

class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.displayNameOrDefault,
                style: TextStyle(
                  fontFamily: AppTypography.headlineFontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (user.isVerified) ...[
              Spacing.hXs,
              const Icon(
                Icons.verified,
                size: 18,
                color: AppColors.primaryContainer,
              ),
            ],
          ],
        ),
        if (user.username != null && user.username!.isNotEmpty) ...[
          Spacing.vXs,
          Text(
            '@${user.username}',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: context.textSecondary,
            ),
          ),
        ],
        if (user.bio != null && user.bio!.isNotEmpty) ...[
          Spacing.vXs,
          Text(
            user.bio!,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              color: context.textPrimary,
            ),
          ),
        ],
        if (user.city != null && user.city!.isNotEmpty) ...[
          Spacing.vXs,
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: context.textSecondary),
              Spacing.hXs,
              Text(
                user.city!,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
