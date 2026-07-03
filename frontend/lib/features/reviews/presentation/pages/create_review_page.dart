import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/user_avatar.dart';
import 'package:freebay/features/reviews/domain/usecases/create_review_usecase.dart';
import 'package:freebay/features/reviews/presentation/providers/review_providers.dart';
import 'package:freebay/features/reviews/presentation/widgets/star_rating_input.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/page_header.dart';

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
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  static const int _maxImages = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= _maxImages) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Câmera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeria'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() => _selectedImages.add(File(picked.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
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

    final result = await ref.read(createReviewUsecaseProvider)(
      CreateReviewParams(
        orderId: widget.orderId,
        reviewedId: widget.reviewedId,
        type: widget.reviewType,
        score: _score,
        comment: _commentController.text.trim(),
        imagePaths: _selectedImages.map((f) => f.path).toList(),
      ),
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
    final isDark = context.isDark;
    final isBuyerReviewing = widget.reviewType == 'BUYER_REVIEWING_SELLER';

    return Scaffold(
      backgroundColor: context.surfaceMidColor,
      body: Column(
        children: [
          PageHeader(
            text: 'AVALIAR',
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Icon(
                  Icons.close,
                  color: context.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BrutalistBreadcrumb(items: [
                    BreadcrumbItem(label: 'Perfil', onTap: () => context.pop()),
                    const BreadcrumbItem(label: 'Avaliar'),
                  ]),
                  Spacing.vMd,
                  UserAvatar(
                    imageUrl: widget.reviewedAvatarUrl,
                    size: AppAvatarSize.large,
                  ),
                  Spacing.vMd,
                  Text(
                    widget.reviewedName,
                    style: TextStyle(
                      fontFamily: AppTypography.headlineFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.inverseOnSurface
                          : AppColors.onSurface,
                    ),
                  ),
                  Spacing.vXs,
                  Text(
                    isBuyerReviewing ? 'VENDEDOR' : 'COMPRADOR',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: AppColors.outline,
                    ),
                  ),
                  Spacing.vXl,
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
                            fontFamily: AppTypography.headlineFontFamily,
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
                        Spacing.vSm,
                        Text(
                          _getScoreLabel(),
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
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
                  Spacing.vLg,
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
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                            color: AppColors.outline,
                          ),
                        ),
                        Spacing.vSm,
                        TextField(
                          controller: _commentController,
                          maxLines: 4,
                          maxLength: 500,
                          enabled: !_isSubmitting,
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
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
                              borderSide:
                                  BorderSide(color: AppColors.outlineVariant),
                            ),
                            counterStyle: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              color: AppColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.vLg,
                  Container(
                    width: double.infinity,
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLowest,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fotos (opcional)',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: AppColors.outline,
                              ),
                            ),
                            if (_selectedImages.isNotEmpty)
                              Text(
                                '${_selectedImages.length}/$_maxImages',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  color: AppColors.outline,
                                ),
                              ),
                          ],
                        ),
                        Spacing.vSm,
                        SizedBox(
                          height: 100,
                          child: Row(
                            children: [
                              if (_selectedImages.length < _maxImages)
                                GestureDetector(
                                  onTap: _isSubmitting ? null : _pickImage,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.outline,
                                        width: 2,
                                      ),
                                      color: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.surface,
                                    ),
                                    child: const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: AppColors.outline,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              if (_selectedImages.isNotEmpty)
                                const SizedBox(width: 8),
                              Expanded(
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedImages.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.outline,
                                              width: 2,
                                            ),
                                          ),
                                          child: Image.file(
                                            _selectedImages[index],
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: _isSubmitting
                                                ? null
                                                : () => _removeImage(index),
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              color: Colors.black87,
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.vXl,
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Enviar avaliação',
                      onPressed:
                          _score > 0 && !_isSubmitting ? _submitReview : null,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
