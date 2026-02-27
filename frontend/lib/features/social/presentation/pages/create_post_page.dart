import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({super.key});

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  String? _selectedImageBase64;
  String _postType = 'REGULAR';
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
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _createPost() async {
    if (_contentController.text.isEmpty && _selectedImageBase64 == null) {
      AppSnackbar.warning(context, 'Adicione um texto ou imagem');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(socialRepositoryProvider);
      final result = await repository.createPost(
        content:
            _contentController.text.isNotEmpty ? _contentController.text : null,
        imageUrl: _selectedImageBase64,
        type: _postType,
      );

      result.fold(
        (failure) {
          AppSnackbar.error(context, failure.message);
        },
        (post) {
          ref.read(feedProvider.notifier).addPost(post);
          AppSnackbar.success(context, 'Post publicado com sucesso!');
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
          'Criar Post',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.white : AppColors.darkGray,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close,
              color: isDark ? AppColors.white : AppColors.darkGray),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isDark ? AppColors.surfaceDark : AppColors.lightGray,
                  child: const Icon(Icons.person, color: AppColors.mediumGray),
                ),
                const SizedBox(width: 12),
                Text(
                  'Você',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 5,
              style: TextStyle(
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
              decoration: InputDecoration(
                hintText: 'No que você está pensando ou vendendo?',
                hintStyle: TextStyle(
                  color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                ),
                border: InputBorder.none,
              ),
            ),
            if (_selectedImageBase64 != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      base64Decode(_selectedImageBase64!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImageBase64 = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
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
            const SizedBox(height: 24),
            Text(
              'Tipo de post',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.white : AppColors.darkGray,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTypeChip(
                  isDark,
                  'REGULAR',
                  'Padrão',
                  Icons.article_outlined,
                ),
                const SizedBox(width: 8),
                _buildTypeChip(
                  isDark,
                  'PRODUCT',
                  'Produto',
                  Icons.sell_outlined,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_postType == 'PRODUCT') ...[
              Text(
                'Adicionar imagem do produto',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.darkGray,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primaryPurple,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.primaryPurple.withAlpha(26),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppColors.primaryPurple,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecionar imagem',
                        style: TextStyle(
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      color: AppColors.primaryPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Adicionar imagem',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.w500,
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

  Widget _buildTypeChip(bool isDark, String type, String label, IconData icon) {
    final isSelected = _postType == type;
    return GestureDetector(
      onTap: () => setState(() => _postType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple
              : (isDark ? AppColors.surfaceDark : AppColors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : AppColors.mediumGray.withAlpha(77),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.white
                  : (isDark ? AppColors.white : AppColors.darkGray),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.white
                    : (isDark ? AppColors.white : AppColors.darkGray),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
