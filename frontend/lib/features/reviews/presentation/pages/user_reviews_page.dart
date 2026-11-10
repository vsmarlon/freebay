import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/domain/usecases/get_user_reviews_usecase.dart';
import 'package:freebay/features/reviews/presentation/providers/review_providers.dart';
import 'package:freebay/features/reviews/presentation/widgets/review_card.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

final userReviewsProvider = FutureProvider.family<ReviewListResponse, String>((
  ref,
  userId,
) async {
  final usecase = ref.watch(getUserReviewsUsecaseProvider);
  final result = await usecase(GetUserReviewsParams(userId: userId));
  return result.fold((failure) => throw failure, (response) => response);
});

class UserReviewsPage extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const UserReviewsPage({super.key, required this.userId, this.userName});

  @override
  ConsumerState<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends ConsumerState<UserReviewsPage> {
  final List<ReviewEntity> _reviews = [];
  bool _isLoading = false;
  bool _hasMore = false;
  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _offset = 0;
      _reviews.clear();
    }
    setState(() => _isLoading = true);

    final usecase = ref.read(getUserReviewsUsecaseProvider);
    final result = await usecase(
      GetUserReviewsParams(
        userId: widget.userId,
        limit: _limit,
        offset: _offset,
      ),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold((failure) {}, (response) {
      setState(() {
        _reviews.addAll(response.reviews);
        _hasMore = response.hasMore;
        _offset += response.reviews.length;
      });
    });
  }

  Future<void> _refresh() => _loadReviews(refresh: true);

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.reviewsTitle.toUpperCase(),
              subtitle: widget.userName,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            BrutalistBreadcrumb(items: context.breadcrumbs),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.primaryContainer,
                child: _buildContent(isDark, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, BuildContext context) {
    final strings = l10n(context);
    if (_reviews.isEmpty && _isLoading) {
      return SkeletonPage(
        child: SkeletonList(
          itemCount: 4,
          itemBuilder: (_, i) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBlock(width: 40, height: 40),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ShimmerBlock(height: 14, width: 16),
                            SizedBox(width: 2),
                            ShimmerBlock(height: 14, width: 16),
                            SizedBox(width: 2),
                            ShimmerBlock(height: 14, width: 16),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBlock(height: 14),
                SizedBox(height: 4),
                ShimmerBlock(height: 14, width: 200),
              ],
            ),
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return EmptyState(
        icon: Icons.rate_review_outlined,
        title: strings.reviewsEmptyTitle,
        subtitle: strings.reviewsEmptyBody,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _reviews.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _reviews.length) {
          _loadReviews();
          return const ShimmerScope(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ShimmerBlock(height: 60),
            ),
          );
        }

        final review = _reviews[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ReviewCard(
            review: review,
            onTapUser: () {
              if (review.reviewer != null) {
                context.push(AppRoutes.userPath(review.reviewer!.id));
              }
            },
          ),
        );
      },
    );
  }
}
