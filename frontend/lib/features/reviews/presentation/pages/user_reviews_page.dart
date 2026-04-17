import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/data/services/review_service.dart';
import 'package:freebay/features/reviews/presentation/widgets/review_card.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final userReviewsProvider = FutureProvider.family<ReviewListResponse, String>(
  (ref, userId) async {
    final service = ref.watch(reviewServiceProvider);
    final result = await service.getUserReviews(userId);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (response) => response,
    );
  },
);

class UserReviewsPage extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;

  const UserReviewsPage({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  ConsumerState<UserReviewsPage> createState() => _UserReviewsPageState();
}

class _UserReviewsPageState extends ConsumerState<UserReviewsPage> {
  final List<ReviewEntity> _reviews = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 10;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    final service = ref.read(reviewServiceProvider);
    final result = await service.getUserReviews(
      widget.userId,
      limit: _limit,
      offset: _offset,
    );

    result.fold(
      (failure) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      (response) {
        setState(() {
          _reviews.addAll(response.reviews);
          _hasMore = response.hasMore;
          _offset += response.reviews.length;
        });
      },
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _reviews.clear();
      _offset = 0;
      _hasMore = true;
    });
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avaliações',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
            if (widget.userName != null)
              Text(
                widget.userName!,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.outline,
                ),
              ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryContainer,
        child: _buildContent(isDark),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_reviews.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryContainer,
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma avaliação',
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este usuário ainda não recebeu avaliações.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _reviews.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _reviews.length) {
          _loadReviews();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryContainer,
              ),
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
                context.push('/user/${review.reviewer!.id}');
              }
            },
          ),
        );
      },
    );
  }
}
