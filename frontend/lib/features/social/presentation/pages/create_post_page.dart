import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

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

    try {
      final repository = ref.read(socialRepositoryProvider);
      final result = await repository.createPost(
        content:
            _contentController.text.isNotEmpty ? _contentController.text : null,
        imagePath: _selectedImagePath,
        type: 'REGULAR',
      );

      result.fold(
        (failure) {
          AppSnackbar.error(context, failure.message);
        },
        (post) {
          ref.read(feedProvider.notifier).addPost(post);
          AppSnackbar.success(context, 'Publicacao social criada com sucesso!');
          context.pop();
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Nova publicacao',
          style: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDark ? AppColors.white : AppColors.onSurface,
          ),
          onPressed: () => context.pop(),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSeparationCard(context, isDark),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  color: isDark ? AppColors.surfaceContainerDark : AppColors.lightGray,
                  child: const Icon(Icons.person, color: AppColors.mediumGray),
                ),
                const SizedBox(width: 12),
                Text(
                  'Publicacao social',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.white : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
                        color: Colors.black54,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
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
                    const SizedBox(width: 8),
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
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use esta tela para posts do feed. Para vender um item, crie um anuncio separado para manter a experiencia mais limpa.',
            style: TextStyle(
              color: isDark ? AppColors.inverseOnSurface : AppColors.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.push('/create-product'),
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
                  const SizedBox(width: 10),
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
