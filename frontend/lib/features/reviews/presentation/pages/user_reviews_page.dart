import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/empty_state.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/data/services/review_service.dart';
import 'package:freebay/features/reviews/presentation/widgets/review_card.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';

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
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.surfaceMidColor,
      body: Column(
        children: [
          PageHeader(
            text: 'AVALIAÇÕES',
            subtitle: widget.userName,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          BrutalistBreadcrumb(items: [
            BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
            const BreadcrumbItem(label: 'Avaliações'),
          ]),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primaryContainer,
              child: _buildContent(isDark),
            ),
          ),
        ],
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
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'NENHUMA AVALIAÇÃO',
        subtitle: 'Este usuário ainda não recebeu avaliações.',
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
