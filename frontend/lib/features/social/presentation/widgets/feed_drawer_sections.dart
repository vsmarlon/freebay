import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class FeedDrawerHeader extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isVerified;
  final VoidCallback onTap;

  const FeedDrawerHeader({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surfaceMidColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 12, 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: context.borderColor.withAlpha(50),
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(
                imageUrl: avatarUrl,
                isVerified: isVerified,
                size: AppAvatarSize.large,
              ),
              Spacing.hMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: context.textPrimary,
                      ),
                    ),
                    Spacing.vXs,
                    const Text(
                      'VER MEU PERFIL',
                      style: TextStyle(
                        fontFamily: AppTypography.headlineFontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class FeedDrawerStats extends StatelessWidget {
  final int followers;
  final int following;
  final int sales;
  final num reputation;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;

  const FeedDrawerStats({
    super.key,
    required this.followers,
    required this.following,
    required this.sales,
    required this.reputation,
    required this.onFollowers,
    required this.onFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Container(
      color: context.surfaceMidColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatColumn(
                  label: strings.profileFollowers,
                  value: '$followers',
                  uppercaseLabel: true,
                  onTap: onFollowers,
                ),
              ),
              Expanded(
                child: StatColumn(
                  label: strings.profileFollowing,
                  value: '$following',
                  uppercaseLabel: true,
                  onTap: onFollowing,
                ),
              ),
            ],
          ),
          Spacing.vMd,
          Row(
            children: [
              Expanded(
                child: StatColumn(
                  label: strings.profileSales,
                  value: '$sales',
                  uppercaseLabel: true,
                ),
              ),
              Expanded(
                child: StatColumn(
                  label: strings.profileReputation,
                  value: reputation.toStringAsFixed(1),
                  uppercaseLabel: true,
                  usePrimaryColor: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeedDrawerBio extends StatelessWidget {
  final String bio;

  const FeedDrawerBio({super.key, required this.bio});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BIO',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bio,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 13,
              color: context.textPrimary,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
