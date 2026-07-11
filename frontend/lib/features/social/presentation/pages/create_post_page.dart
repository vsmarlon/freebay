import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/features/social/presentation/widgets/local_image_inspector.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _contentController = TextEditingController();
  final _mentionController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _mentionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    final pickedFile = await _imagePicker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
      });
    }
  }

  void _showImageOptions() {
    showBrutalistSheet(
      context: context,
      title: 'OPÇÕES DE IMAGEM',
      builder: (ctx) => ImageOptionsSheet(
        hasImage: _selectedImagePath != null,
        onPickGallery: () {
          Navigator.pop(ctx);
          _pickImage();
        },
        onPickCamera: () {
          Navigator.pop(ctx);
          _pickImage(fromCamera: true);
        },
        onView: _selectedImagePath != null
            ? () {
                Navigator.pop(ctx);
                _openImagePreview();
              }
            : null,
        onRemove: _selectedImagePath != null
            ? () {
                Navigator.pop(ctx);
                setState(() => _selectedImagePath = null);
              }
            : null,
      ),
    );
  }

  void _openImagePreview() {
    if (_selectedImagePath == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => LocalImageFullScreen(
          path: _selectedImagePath!,
          onEdit: () {
            Navigator.of(context).pop();
            _showImageOptions();
          },
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _createPost() async {
    final rawContent = _contentController.text.trim();
    final mention = _mentionController.text.trim();

    String? content = rawContent.isNotEmpty ? rawContent : null;
    if (mention.isNotEmpty && content != null) {
      content = '$content\n@$mention';
    } else if (mention.isNotEmpty) {
      content = '@$mention';
    }

    if (content == null && _selectedImagePath == null) {
      AppSnackbar.warning(context, 'Adicione um texto ou imagem.');
      return;
    }

    setState(() => _isLoading = true);

    final repository = ref.read(socialRepositoryProvider);
    final result = await repository.createPost(
      content: content,
      imagePath: _selectedImagePath,
      type: 'REGULAR',
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    result.fold(
      (failure) {
        AppSnackbar.error(context, failure.message);
      },
      (post) {
        ref.read(feedProvider.notifier).addPost(post);
        context.pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'NOVA PUBLICAÇÃO',
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
                  color: isDark ? AppColors.white : AppColors.onSurface,
                  size: 20,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppButton(
                  label: 'Publicar',
                  onPressed: _isLoading ? null : _createPost,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  context.breadcrumbs.isNotEmpty
                      ? BrutalistBreadcrumb(items: context.breadcrumbs)
                      : const SizedBox.shrink(),
                  Spacing.vMd,
                  _buildSeparationCard(context, isDark),
                  Spacing.vMd,
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        color: isDark
                            ? AppColors.surfaceContainerDark
                            : AppColors.lightGray,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.mediumGray,
                        ),
                      ),
                      Spacing.hSm,
                      Flexible(
                        child: Text(
                          'Publicação social',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: AppTypography.headlineFontFamily,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.white
                                : AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.vMd,
                  Container(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLowest,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 5,
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Compartilhe uma atualização, ideia ou bastidor…',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.outline,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Spacing.vSm,
                  // Mention field
                  Container(
                    color: isDark
                        ? AppColors.surfaceContainerDark
                        : AppColors.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email,
                          size: 18,
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.outline,
                        ),
                        Spacing.hSm,
                        Expanded(
                          child: TextField(
                            controller: _mentionController,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Mencionar usuário (opcional)',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? AppColors.mediumGray
                                    : AppColors.outline,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedImagePath != null) ...[
                    Spacing.vMd,
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _openImagePreview,
                          child: Stack(
                            children: [
                              Image.file(
                                File(_selectedImagePath!),
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.0),
                                  alignment: Alignment.bottomLeft,
                                  padding: const EdgeInsets.all(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    color: Colors.black.withValues(alpha: 0.6),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.zoom_in,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'AMPLIAR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: _showImageOptions,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  color: AppColors.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: AppColors.onPrimary,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImagePath = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  color: AppColors.error.withValues(
                                    alpha: 0.85,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: AppColors.onPrimary,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  Spacing.vMd,
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      color: isDark
                          ? AppColors.surfaceContainerDark
                          : AppColors.surfaceContainer,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: AppColors.primaryContainer,
                          ),
                          Spacing.hSm,
                          Text(
                            _selectedImagePath == null
                                ? 'Adicionar imagem ao post'
                                : 'Editar imagem',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.white
                                  : AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSeparationCard(BuildContext context, bool isDark) {
    return Container(
      color: isDark
          ? AppColors.surfaceContainerDark
          : AppColors.surfaceContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PUBLICAÇÃO SOCIAL × ANÚNCIO',
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
          Spacing.vSm,
          Text(
            'Esta tela é para posts do feed — textos, fotos e atualizações. '
            'Para vender um item com preço, categoria e ficha técnica, crie um anúncio separado.',
            style: TextStyle(
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/products/create'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.onSurface, width: 2),
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceContainerLowest,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sell_outlined,
                    color: AppColors.primaryContainer,
                    size: 18,
                  ),
                  Spacing.hSm,
                  const Expanded(
                    child: Text(
                      'Criar anúncio de venda',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.primaryContainer,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
