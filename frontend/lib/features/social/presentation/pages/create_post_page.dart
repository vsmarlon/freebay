import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (pickedFile != null && mounted) {
      setState(() => _selectedImagePath = pickedFile.path);
    }
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
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    result.fold((failure) => AppSnackbar.error(context, failure.message), (
      post,
    ) {
      ref.read(feedProvider.notifier).addPost(post);
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

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
                child: Icon(Icons.close, color: context.textPrimary, size: 20),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppButton(
                  label: 'PUBLICAR',
                  size: AppButtonSize.compact,
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
                  Row(
                    children: [
                      UserAvatar(imageUrl: user?.avatarUrl),
                      Spacing.hSm,
                      Text(
                        user?.displayNameOrDefault ?? 'Meu perfil',
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Spacing.vMd,
                  Container(
                    color: context.surfaceColor,
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 5,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText:
                            'Compartilhe uma atualização, ideia ou bastidor…',
                        hintStyle: TextStyle(color: context.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Spacing.vSm,
                  Container(
                    color: context.surfaceColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.alternate_email,
                          size: 18,
                          color: context.textSecondary,
                        ),
                        Spacing.hSm,
                        Expanded(
                          child: TextField(
                            controller: _mentionController,
                            style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Mencionar usuário (opcional)',
                              hintStyle: TextStyle(
                                color: context.textSecondary,
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
                            onTap: () =>
                                setState(() => _selectedImagePath = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              color: Colors.black.withAlpha(180),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  Spacing.vMd,
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text('Galeria'),
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(),
                        ),
                      ),
                      Spacing.hSm,
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Câmera'),
                        style: OutlinedButton.styleFrom(
                          shape: const RoundedRectangleBorder(),
                        ),
                      ),
                    ],
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
