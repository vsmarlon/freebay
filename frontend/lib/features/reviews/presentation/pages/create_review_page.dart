import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/features/reviews/data/entities/review_entity.dart';
import 'package:freebay/features/reviews/domain/usecases/create_review_usecase.dart';
import 'package:freebay/features/reviews/presentation/providers/review_providers.dart';
import 'package:freebay/features/reviews/presentation/widgets/star_rating_input.dart';

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
  List<File> _selectedImages = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_score == 0) {
      AppSnackbar.error(context, 'Selecione uma nota de 1 a 5 estrelas.');
      return;
    }

    setState(() => _isSubmitting = true);

    final usecase = ref.read(createReviewUsecaseProvider);
    final result = await usecase(
      CreateReviewParams(
        orderId: widget.orderId,
        reviewedId: widget.reviewedId,
        type: reviewTypeFromApiValue(widget.reviewType),
        score: _score,
        comment: _commentController.text.trim().isEmpty
            ? null
            : _commentController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      ),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold((failure) => AppSnackbar.error(context, failure.message), (_) {
      AppSnackbar.success(context, 'Avaliação enviada com sucesso!');
      context.pop(true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: 'AVALIAR',
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                onTap: () => context.pop(),
              ),
              breadcrumbs: context.breadcrumbs,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceColor,
                        border: Border.all(
                          color: context.borderColor,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          UserAvatar(imageUrl: widget.reviewedAvatarUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.reviewedName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                Text(
                                  widget.reviewType == 'SELLER_REVIEW'
                                      ? 'Vendedor'
                                      : 'Comprador',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacing.vLg,
                    Text(
                      'SUA NOTA',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    Spacing.vSm,
                    Center(
                      child: StarRatingInput(
                        value: _score,
                        onChanged: (val) => setState(() => _score = val),
                      ),
                    ),
                    Spacing.vLg,
                    Text(
                      'COMENTÁRIO (OPCIONAL)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    Spacing.vSm,
                    TextField(
                      controller: _commentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Conte como foi sua experiência...',
                        hintStyle: TextStyle(color: context.textSecondary),
                        filled: true,
                        fillColor: context.surfaceColor,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: context.borderColor,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: context.borderColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    Spacing.vLg,
                    Text(
                      'FOTOS (OPCIONAL)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: context.textPrimary,
                      ),
                    ),
                    Spacing.vSm,
                    ImagePickerGrid(
                      images: _selectedImages,
                      onImagesChanged: (imgs) =>
                          setState(() => _selectedImages = imgs),
                    ),
                    Spacing.vXl,
                    AppButton(
                      label: 'ENVIAR AVALIAÇÃO',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
