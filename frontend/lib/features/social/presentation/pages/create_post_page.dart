import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_breadcrumb.dart';
import 'package:freebay/core/components/page_header.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();

  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
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

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty && _selectedImagePath == null) {
      AppSnackbar.warning(context, 'Adicione um texto ou imagem');
      return;
    }

    setState(() => _isLoading = true);

    final repository = ref.read(socialRepositoryProvider);
    final result = await repository.createPost(
      content:
          _contentController.text.isNotEmpty ? _contentController.text : null,
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
                child: InkWell(
                  onTap: _isLoading ? null : _createPost,
                  child: Container(
                    height: 40,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: AppColors.brutalistGradient,
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : const Text(
                              'Publicar',
                              style: TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
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
                  BrutalistBreadcrumb(items: [
                    BreadcrumbItem(label: 'Feed', onTap: () => context.pop()),
                    const BreadcrumbItem(label: 'Nova Publicação'),
                  ]),
                  Spacing.vMd,
                  _buildSeparationCard(context, isDark),
                  Spacing.vMd,
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
                        child: const Icon(Icons.person, color: AppColors.mediumGray),
                      ),
                      Spacing.hSm,
                      Text(
                        'Publicacao social',
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.white : AppColors.onSurface,
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
                        hintText: 'Compartilhe uma atualizacao, ideia ou bastidor.',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.mediumGray : AppColors.outline,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_selectedImagePath != null) ...[
                    Spacing.vMd,
                    Stack(
                      children: [
                        Image.file(
                          File(_selectedImagePath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedImagePath = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              color: AppColors.onSurface.withValues(alpha: 0.54),
                              child: const Icon(
                                Icons.close,
                                color: AppColors.onPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Spacing.vMd,
                  InkWell(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                                : 'Trocar imagem',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.white : AppColors.onSurface,
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
      color: isDark ? AppColors.surfaceContainerDark : AppColors.surfaceContainer,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOCIAL E VENDA AGORA FICAM SEPARADOS',
            style: TextStyle(
              fontFamily: AppTypography.headlineFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
          Spacing.vSm,
          Text(
            'Use esta tela para posts do feed. Para vender um item, crie um anuncio separado para manter a experiencia mais limpa.',
            style: TextStyle(
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/products/create'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.onSurface, width: 2),
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceContainerLowest,
              ),
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, color: AppColors.primaryContainer),
                  Spacing.hSm,
                  Expanded(
                    child: Text(
                      'Criar anuncio de venda',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.white : AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: AppColors.primaryContainer),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
