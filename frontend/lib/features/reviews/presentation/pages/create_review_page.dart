import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/reviews/data/services/review_service.dart';
import 'package:freebay/features/reviews/presentation/widgets/star_rating_input.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

class CreateReviewPage extends ConsumerStatefulWidget {
  final String orderId;
  final String reviewedId;
  final String reviewedName;
  final String? reviewedAvatarUrl;
  final String reviewType;

  const CreateReviewPage({
    super.key,
    required this.orderId,
    required this.reviewedId,
    required this.reviewedName,
    this.reviewedAvatarUrl,
    required this.reviewType,
  });

  @override
  ConsumerState<CreateReviewPage> createState() => _CreateReviewPageState();
}

class _CreateReviewPageState extends ConsumerState<CreateReviewPage> {
  int _score = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_score == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma nota de 1 a 5 estrelas'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final service = ref.read(reviewServiceProvider);
    final result = await service.createReview(
      orderId: widget.orderId,
      reviewedId: widget.reviewedId,
      type: widget.reviewType,
      score: _score,
      comment: _commentController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
            backgroundColor: AppColors.error,
          ),
        );
      },
      (review) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avaliação enviada com sucesso!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBuyerReviewing = widget.reviewType == 'BUYER_REVIEWING_SELLER';

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Avaliar',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.inverseOnSurface
                : AppColors.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            UserAvatar(
              imageUrl: widget.reviewedAvatarUrl,
              size: AppAvatarSize.large,
            ),
            const SizedBox(height: 16),
            Text(
              widget.reviewedName,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.inverseOnSurface
                    : AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isBuyerReviewing ? 'VENDEDOR' : 'COMPRADOR',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Como foi sua experiência?',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StarRatingInput(
                    value: _score,
                    onChanged: (value) => setState(() => _score = value),
                    size: 48,
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreLabel(),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _score > 0
                          ? AppColors.primaryContainer
                          : AppColors.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              color: isDark
                  ? AppColors.surfaceContainerDark
                  : AppColors.surfaceContainerLowest,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comentário (opcional)',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: AppColors.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    maxLength: 500,
                    enabled: !_isSubmitting,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Conte como foi sua experiência...',
                      hintStyle: TextStyle(
                        color: AppColors.outline,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surface,
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.outline),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: AppColors.primaryContainer,
                          width: 2,
                        ),
                      ),
                      disabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: AppColors.outlineVariant),
                      ),
                      counterStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _score > 0 && !_isSubmitting
                      ? AppColors.brutalistGradient
                      : null,
                  color: _score == 0 || _isSubmitting
                      ? AppColors.surfaceContainerHighest
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _score > 0 && !_isSubmitting ? _submitReview : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              )
                            : Text(
                                'Enviar avaliação',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _score > 0
                                      ? AppColors.onPrimary
                                      : AppColors.outline,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreLabel() {
    switch (_score) {
      case 1:
        return 'Péssimo';
      case 2:
        return 'Ruim';
      case 3:
        return 'Regular';
      case 4:
        return 'Bom';
      case 5:
        return 'Excelente';
      default:
        return 'Toque para avaliar';
    }
  }
}
