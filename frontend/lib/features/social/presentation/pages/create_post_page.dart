import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_models.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';

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
  PostAudience _audience = PostAudience.everyone;

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
      final bytes = await pickedFile.readAsBytes();
      if (!mounted) return;
      await context.push(
        AppRoutes.imageEditor,
        extra: {
          'imageBytes': bytes,
          'purpose': ImageEditorPurpose.post,
          'onComplete': (ImageEditorResult result) async {
            final editedFile = File(
              '${Directory.systemTemp.path}${Platform.pathSeparator}freebay_post_${DateTime.now().microsecondsSinceEpoch}.png',
            );
            await editedFile.writeAsBytes(result.imageBytes, flush: true);
            if (mounted) {
              setState(() => _selectedImagePath = editedFile.path);
              final caption = result.caption?.trim();
              if (caption?.isNotEmpty == true &&
                  _contentController.text.trim().isEmpty) {
                _contentController.text = caption!;
              }
            }
            return true;
          },
        },
      );
    }
  }

  Future<void> _createPost() async {
    final rawContent = _contentController.text.trim();
    final mention = _mentionController.text.trim();

    String? content = rawContent.isNotEmpty ? rawContent : null;
    if (_audience == PostAudience.everyone &&
        mention.isNotEmpty &&
        content != null) {
      content = '$content\n@$mention';
    } else if (_audience == PostAudience.everyone && mention.isNotEmpty) {
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
      audience: _audience,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    result.fold((failure) => AppSnackbar.error(context, failure.message), (
      post,
    ) {
      ref.read(feedProvider.notifier).addPost(post);
      final currentUser = ref.read(authControllerProvider).value;
      if (currentUser != null) {
        ref.invalidate(userPostsProvider(currentUser.id));
        ref.invalidate(profileTimelineProvider(currentUser.id));
      }
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
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
                    color: context.textPrimary,
                    size: 20,
                  ),
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
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'PÚBLICO',
                            variant: _audience == PostAudience.everyone
                                ? AppButtonVariant.primary
                                : AppButtonVariant.secondary,
                            onPressed: () => setState(
                              () => _audience = PostAudience.everyone,
                            ),
                          ),
                        ),
                        Spacing.hSm,
                        Expanded(
                          child: AppButton(
                            label: 'AMIGOS PRÓXIMOS',
                            variant: _audience == PostAudience.closeFriends
                                ? AppButtonVariant.primary
                                : AppButtonVariant.secondary,
                            onPressed: () => setState(
                              () => _audience = PostAudience.closeFriends,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_audience == PostAudience.closeFriends) ...[
                      Spacing.vSm,
                      Text(
                        'Só seguidores da sua lista poderão ver este post.',
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      AppButton(
                        label: 'EDITAR LISTA',
                        variant: AppButtonVariant.ghost,
                        onPressed: () =>
                            context.push(AppRoutes.profileCloseFriends),
                      ),
                    ],
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
                    if (_audience == PostAudience.everyone)
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
      ),
    );
  }
}
