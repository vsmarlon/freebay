import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart' hide UserEntity;
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/widgets/profile_menu_list.dart';

class ProfileTabs extends ConsumerStatefulWidget {
  final UserEntity user;
  final int salesCount;
  final int purchasesCount;

  const ProfileTabs({
    super.key,
    required this.user,
    this.salesCount = 0,
    this.purchasesCount = 0,
  });

  @override
  ConsumerState<ProfileTabs> createState() => _ProfileTabsState();
}

class _ProfileTabsState extends ConsumerState<ProfileTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: context.textPrimary,
          unselectedLabelColor: AppColors.mediumGray,
          indicatorColor: AppColors.primaryContainer,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorWeight: 2,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_view, size: 18),
                  Spacing.hSm,
                  Text(
                    'Posts',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 18),
                  Spacing.hSm,
                  Text(
                    'Sobre',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          height: 500,
          child: TabBarView(
            controller: _tabController,
            children: [
              _PostsTab(userId: widget.user.id),
              _AboutTab(
                user: widget.user,
                salesCount: widget.salesCount,
                purchasesCount: widget.purchasesCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PostsTab extends ConsumerWidget {
  final String userId;

  const _PostsTab({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: AppColors.mediumGray.withAlpha(100),
                  ),
                  Spacing.vMd,
                  Text(
                    'Nenhum post ainda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  Spacing.vSm,
                  const Text(
                    'Compartilhe momentos no seu perfil',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.mediumGray,
                    ),
                  ),
                  Spacing.vLg,
                  InkWell(
                    onTap: () => context.push('/create-story'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        gradient: AppColors.brutalistGradient,
                      ),
                      child: const Text(
                        'Criar post',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _PostGridTile(post: post);
          },
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryContainer,
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PostGridTile extends StatelessWidget {
  final PostEntity post;

  const _PostGridTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.zero,
        ),
        child: post.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: post.imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return const Center(
      child: Icon(
        Icons.photo,
        color: AppColors.mediumGray,
        size: 24,
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final UserEntity user;
  final int salesCount;
  final int purchasesCount;

  const _AboutTab({
    required this.user,
    required this.salesCount,
    required this.purchasesCount,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            Text(
              'BIO',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
                color: AppColors.mediumGray,
              ),
            ),
            Spacing.vSm,
            Text(
              user.bio!,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: context.textPrimary,
              ),
            ),
            Spacing.vLg,
          ],
          Text(
            'STATS',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AppColors.mediumGray,
            ),
          ),
          Spacing.vSm,
          Row(
            children: [
              _InfoChip(
                icon: Icons.shopping_bag_outlined,
                label: '$salesCount vendas',
              ),
              Spacing.hMd,
              _InfoChip(
                icon: Icons.shopping_cart_outlined,
                label: '$purchasesCount compras',
              ),
            ],
          ),
          Spacing.vSm,
          Row(
            children: [
              _InfoChip(
                icon: Icons.star_outline,
                label: '${user.reputationScore} reputação',
              ),
              Spacing.hMd,
              _InfoChip(
                icon: Icons.reviews_outlined,
                label: '${user.totalReviews} avaliações',
              ),
            ],
          ),
          Spacing.vLg,
          const ProfileMenuList(),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.surfaceContainerLow,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.mediumGray),
          Spacing.hSm,
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.mediumGray,
            ),
          ),
        ],
      ),
    );
  }
}
