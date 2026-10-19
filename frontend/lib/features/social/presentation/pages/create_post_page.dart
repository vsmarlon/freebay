import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/providers/social_repository_provider.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/providers/profile_timeline_provider.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/data/entities/user_search_entity.dart';
import 'package:freebay/features/social/presentation/providers/user_search_provider.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/shared/services/auth_session_coordinator.dart';
import 'package:uuid/uuid.dart';
import 'package:freebay/features/social/presentation/widgets/quote_source_preview.dart';

class CreatePostPage extends ConsumerStatefulWidget {
  final QuoteSource? quoteSource;
  const CreatePostPage({super.key, this.quoteSource});

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
  String? _quoteRequestId;
  String? _quoteRequestFingerprint;
  final List<UserSearchEntity> _selectedMentionUsers = [];
  String _searchedMentionQuery = '';

  @override
  void dispose() {
    _contentController.dispose();
    _mentionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
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
    } catch (error, stackTrace) {
      ErrorReporter.report('post-media-pick', error, stackTrace);
      if (mounted) {
        AppSnackbar.error(context, l10n(context).feedMediaPickFailed);
      }
    }
  }

  Future<void> _createPost() async {
    if (_isLoading) return;
    final rawContent = _contentController.text.trim();
    final mention = _mentionController.text.trim();

    String? content = rawContent.isNotEmpty ? rawContent : null;
    if (widget.quoteSource == null &&
        _audience == PostAudience.everyone &&
        mention.isNotEmpty &&
        content != null) {
      content = '$content\n@$mention';
    } else if (widget.quoteSource == null &&
        _audience == PostAudience.everyone &&
        mention.isNotEmpty) {
      content = '@$mention';
    }

    if (widget.quoteSource != null &&
        (content == null || content.length > 1000)) {
      AppSnackbar.warning(context, l10n(context).feedPostContentRequired);
      return;
    }
    if (content == null && _selectedImagePath == null) {
      AppSnackbar.warning(context, l10n(context).feedPostContentRequired);
      return;
    }

    setState(() => _isLoading = true);
    final repository = ref.read(socialRepositoryProvider);
    final userIdAtSubmit = ref.read(authControllerProvider).value?.id;
    final authAttempt = AuthSessionCoordinator.currentAuthenticationAttempt;
    final selectedMentionIds =
        _selectedMentionUsers.map((user) => user.id).toSet().toList()..sort();
    final quoteFingerprint =
        '$content|$_selectedImagePath|${widget.quoteSource}|${selectedMentionIds.join(',')}';
    if (quoteFingerprint != _quoteRequestFingerprint) {
      _quoteRequestId = const Uuid().v4();
      _quoteRequestFingerprint = quoteFingerprint;
    }
    final result = widget.quoteSource != null
        ? await repository.createQuote(
            content: content!,
            sourceId: widget.quoteSource!.when(
              post: (id, post) => id,
              comment: (id, postId, comment) => id,
            ),
            sourceIsComment: widget.quoteSource!.maybeWhen(
              comment: (_, _, _) => true,
              orElse: () => false,
            ),
            clientRequestId: _quoteRequestId!,
            mentionIds: selectedMentionIds,
            imagePath: _selectedImagePath,
          )
        : await repository.createPost(
            content: content,
            imagePath: _selectedImagePath,
            audience: _audience,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!AuthSessionCoordinator.isCurrentAttempt(authAttempt) ||
        ref.read(authControllerProvider).value?.id != userIdAtSubmit) {
      return;
    }

    result.fold((failure) => AppSnackbar.error(context, failure.message), (
      post,
    ) {
      ref.read(feedProvider.notifier).addPost(post);
      final currentUser = ref.read(authControllerProvider).value;
      if (currentUser != null) {
        ref.invalidate(userPostsProvider(currentUser.id));
        ref.invalidate(
          profileTimelineProvider(
            currentUser.id,
            kind: 'posts',
            viewerId: currentUser.id,
          ),
        );
      }
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final user = ref.watch(authControllerProvider).value;
    final mentionQuery = _mentionController.text.trim();
    final mentionCandidates =
        widget.quoteSource != null &&
            mentionQuery.isNotEmpty &&
            mentionQuery == _searchedMentionQuery
        ? ref
                  .watch(quoteMentionCandidatesProvider(mentionQuery))
                  .asData
                  ?.value ??
              const <UserSearchEntity>[]
        : const <UserSearchEntity>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.feedCreatePublication.toUpperCase(),
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
                    label: strings.commonPublish,
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
                    if (widget.quoteSource == null)
                      Row(
                        children: [
                          UserAvatar(imageUrl: user?.avatarUrl),
                          Spacing.hSm,
                          Text(
                            user?.displayNameOrDefault ?? strings.commonYou,
                            style: TextStyle(
                              fontFamily: AppTypography.headlineFontFamily,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    Spacing.vMd,
                    if (widget.quoteSource == null)
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: strings.feedAudiencePublic,
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
                              label: strings.feedAudienceCloseFriends,
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
                    if (widget.quoteSource != null) ...[
                      Spacing.vMd,
                      QuoteSourcePreview(source: widget.quoteSource),
                    ],
                    if (widget.quoteSource == null &&
                        _audience == PostAudience.closeFriends) ...[
                      Spacing.vSm,
                      Text(
                        strings.feedCloseFriendsPostDescription,
                        style: AppTypography.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      AppButton(
                        label: strings.feedEditCloseFriends,
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
                        maxLength: widget.quoteSource == null ? null : 1000,
                        maxLines: null,
                        minLines: 5,
                        style: TextStyle(color: context.textPrimary),
                        decoration: InputDecoration(
                          hintText: strings.feedPostContentHint,
                          hintStyle: TextStyle(color: context.textSecondary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Spacing.vSm,
                    if (widget.quoteSource != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mentionController,
                              decoration: InputDecoration(
                                hintText: strings.feedMentionUser,
                              ),
                              onChanged: (_) =>
                                  setState(() => _searchedMentionQuery = ''),
                            ),
                          ),
                          Spacing.hSm,
                          BrutalistIconButton(
                            key: const ValueKey('quote-mention-search'),
                            icon: Icons.search,
                            semanticLabel: strings.commonSearch,
                            onTap: _searchQuoteMentionCandidates,
                          ),
                        ],
                      ),
                      if (_selectedMentionUsers.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final selected in _selectedMentionUsers)
                              InputChip(
                                label: Text(selected.displayName),
                                onDeleted: () => setState(
                                  () => _selectedMentionUsers.removeWhere(
                                    (user) => user.id == selected.id,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (mentionCandidates.isNotEmpty)
                        ...mentionCandidates
                            .where(
                              (candidate) => !_selectedMentionUsers.any(
                                (selected) => selected.id == candidate.id,
                              ),
                            )
                            .take(5)
                            .map(
                              (candidate) => ListTile(
                                leading: UserAvatar(
                                  imageUrl: candidate.avatarUrl,
                                ),
                                title: Text(candidate.displayName),
                                subtitle: candidate.username == null
                                    ? null
                                    : Text('@${candidate.username}'),
                                onTap: () => _selectQuoteMention(candidate),
                              ),
                            ),
                    ],
                    Spacing.vSm,
                    if (widget.quoteSource == null &&
                        _audience == PostAudience.everyone)
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
                                  hintText: strings.feedMentionUser,
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
                                child: Semantics(
                                  button: true,
                                  label: strings.feedRemoveImage,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
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
                          label: Text(strings.commonGallery),
                          style: OutlinedButton.styleFrom(
                            shape: const RoundedRectangleBorder(),
                          ),
                        ),
                        Spacing.hSm,
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: Text(strings.commonCamera),
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

  void _searchQuoteMentionCandidates() {
    final query = _mentionController.text.trim();
    setState(() => _searchedMentionQuery = query);
    if (query.isNotEmpty) {
      ref.read(quoteMentionCandidatesProvider(query));
    }
  }

  void _selectQuoteMention(UserSearchEntity user) {
    if (_selectedMentionUsers.any((selected) => selected.id == user.id)) return;
    setState(() {
      _selectedMentionUsers.add(user);
      _mentionController.clear();
      _searchedMentionQuery = '';
    });
  }
}
