import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';

class ProfileHeader extends ConsumerWidget {
  final UserEntity user;
  final int followersCount;
  final int followingCount;

  const ProfileHeader({
    super.key,
    required this.user,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDark;
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnProfile = currentUser != null && currentUser.id == user.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner container
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: context.borderColor, width: 2),
                color: isDark
                    ? AppColors.surfaceContainerDark
                    : AppColors.surfaceContainer,
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
                        onTap: () => _pickAndUploadBanner(context, ref),
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
            // Avatar positioned bottom left, overlapping
            Positioned(
              left: 16,
              bottom: -40,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 3),
                  color: context.bgColor,
                ),
                child: _AvatarWithStoryRing(user: user),
              ),
            ),
          ],
        ),
        const SizedBox(height: 48), // Spacer for overlapping avatar
        // Name, Bio, Location and Edit Profile section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
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
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 13,
                    color: AppColors.mediumGray,
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
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.mediumGray,
                    ),
                    Spacing.hXs,
                    Text(
                      user.city!,
                      style: const TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 13,
                        color: AppColors.mediumGray,
                      ),
                    ),
                  ],
                ),
              ],
              Spacing.vMd,

              // Stats Row (Posts, Followers, Following)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatColumn(
                    value: '${user.postsCount}',
                    label: 'posts',
                    size: 18,
                  ),
                  StatColumn(
                    value: '$followersCount',
                    label: 'seguidores',
                    size: 18,
                    onTap: () =>
                        context.push('/profile/followers?userId=${user.id}'),
                  ),
                  StatColumn(
                    value: '$followingCount',
                    label: 'seguindo',
                    size: 18,
                    onTap: () =>
                        context.push('/profile/following?userId=${user.id}'),
                  ),
                ],
              ),
              Spacing.vMd,

              if (isOwnProfile)
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () => context.push('/profile/edit'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark
                              ? AppColors.outlineVariant.withAlpha(60)
                              : AppColors.outline.withAlpha(100),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'Editar perfil',
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.primaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadBanner(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image == null) return;

    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.updateBanner(image.path);

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (updatedUser) {
        ref.read(authControllerProvider.notifier).setUser(updatedUser);
        ref.invalidate(profileFutureProvider('me'));
      },
    );
  }
}

class _AvatarWithStoryRing extends ConsumerWidget {
  final UserEntity user;

  const _AvatarWithStoryRing({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStory = user.hasActiveStory;
    final currentUser = ref.watch(authControllerProvider).value;
    final isOwnProfile = currentUser != null && currentUser.id == user.id;

    Widget avatar = GestureDetector(
      onTap: isOwnProfile ? () => _showAvatarOptions(context, ref) : null,
      child: UserAvatar(
        imageUrl: user.avatarUrl,
        isVerified: user.isVerified,
        size: AppAvatarSize.large,
      ),
    );

    if (hasStory) {
      avatar = Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(gradient: AppColors.brutalistGradient),
        child: avatar,
      );
    }

    return avatar;
  }

  void _showAvatarOptions(BuildContext context, WidgetRef ref) {
    showBrutalistSheet(
      context: context,
      title: 'Foto do perfil',
      builder: (sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                ),
                child: const Icon(Icons.camera_alt, color: AppColors.white),
              ),
              title: const Text('Alterar foto do perfil'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAndUploadAvatar(context, ref);
              },
            ),
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                ),
                child: const Icon(Icons.add, color: AppColors.white),
              ),
              title: const Text('Criar história'),
              subtitle: const Text(
                'Compartilhe uma foto ou vídeo',
                style: TextStyle(color: AppColors.mediumGray),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/create-story');
              },
            ),
            if (user.hasActiveStory)
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primaryContainer,
                  ),
                ),
                title: const Text('Ver minhas histórias'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/profile/stories');
                },
              ),
            Spacing.vMd,
          ],
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image == null) return;

    final repository = ref.read(profileRepositoryProvider);
    final result = await repository.updateAvatar(image.path);

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
      (updatedUser) {
        ref.read(authControllerProvider.notifier).setUser(updatedUser);
        ref.invalidate(profileFutureProvider('me'));
      },
    );
  }
}
