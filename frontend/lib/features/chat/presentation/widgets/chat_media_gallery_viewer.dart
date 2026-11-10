import 'dart:async';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/features/chat/presentation/providers/chat_provider.dart';
import 'package:freebay/features/chat/presentation/providers/conversation_messages_provider.dart';
import 'package:freebay/features/chat/presentation/widgets/forward_message_sheet.dart';
import 'package:freebay/features/media_editor/media_editor.dart';
import 'package:freebay/shared/services/http_client.dart';

class ChatMediaGalleryViewer extends ConsumerStatefulWidget {
  final List<MessageEntity> mediaMessages;
  final int initialIndex;
  final ValueChanged<MessageEntity>? onReply;
  final ValueChanged<String>? onDeleted;

  const ChatMediaGalleryViewer({
    super.key,
    required this.mediaMessages,
    required this.initialIndex,
    this.onReply,
    this.onDeleted,
  });

  static List<MessageEntity> extractMedia(List<MessageEntity> messages) {
    return messages.where((m) {
      if (m.deletedAt != null) return false;
      if (m.viewOnce) return false;
      if (m.attachmentUrl == null || m.attachmentUrl!.isEmpty) return false;
      return m.type == MessageType.image ||
          m.type == MessageType.video ||
          m.type == MessageType.gif;
    }).toList();
  }

  @override
  ConsumerState<ChatMediaGalleryViewer> createState() =>
      _ChatMediaGalleryViewerState();
}

class _ChatMediaGalleryViewerState
    extends ConsumerState<ChatMediaGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<String, int> _retryAttempts = {};
  VideoPlayerController? _videoController;
  String? _videoError;
  int _videoGeneration = 0;
  late final List<MessageEntity> _messages;
  bool _busy = false;
  bool _zoomed = false;
  bool _scaling = false;
  Drag? _pageDrag;
  final _transform = TransformationController();

  @override
  void initState() {
    super.initState();
    _messages = ChatMediaGalleryViewer.extractMedia(widget.mediaMessages);
    _currentIndex = _messages.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _messages.length - 1).toInt();
    _pageController = PageController(initialPage: _currentIndex);
    unawaited(_loadCurrentVideo());
  }

  @override
  void dispose() {
    _pageDrag?.cancel();
    _pageController.dispose();
    _transform.dispose();
    _videoGeneration++;
    unawaited(_disposeVideo());
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      _videoError = null;
      _zoomed = false;
      _scaling = false;
      _transform.value = Matrix4.identity();
    });
    HapticFeedback.selectionClick();
    unawaited(_loadCurrentVideo());
  }

  Future<void> _disposeVideo() async {
    final controller = _videoController;
    _videoController = null;
    await controller?.dispose();
  }

  Future<void> _loadCurrentVideo() async {
    final generation = ++_videoGeneration;
    await _disposeVideo();
    if (!mounted || generation != _videoGeneration || _messages.isEmpty) return;
    final message = _messages[_currentIndex];
    if (message.type != MessageType.video || message.attachmentUrl == null) {
      return;
    }
    final url = mediaUrl(message.attachmentUrl!);
    try {
      final headers = isPrivateMedia(url)
          ? await getMediaAuthHeadersAsync(url)
          : null;
      if (!mounted || generation != _videoGeneration) return;
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: headers ?? const {},
      );
      _videoController = controller;
      await controller.initialize();
      if (!mounted || generation != _videoGeneration) {
        return;
      }
      await controller.play();
      if (mounted && generation == _videoGeneration) {
        setState(() => _videoError = null);
      }
    } catch (_) {
      if (mounted && generation == _videoGeneration) {
        setState(() => _videoError = l10n(context).chatMediaUnavailable);
      }
    }
  }

  void _onThumbnailTap(int index) {
    _pageController.animateToPage(
      index,
      duration: AppMotion.tap,
      curve: AppMotion.baseCurve,
    );
  }

  void _onMediaInteractionStart(ScaleStartDetails details) {
    if (details.pointerCount > 1) {
      _pageDrag?.cancel();
      _pageDrag = null;
      _pageController.jumpToPage(_currentIndex);
      setState(() => _scaling = true);
      return;
    }
    if (_zoomed || _scaling) return;
    _pageDrag = _pageController.position.drag(
      DragStartDetails(globalPosition: details.focalPoint),
      () => _pageDrag = null,
    );
  }

  void _onMediaInteractionUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount > 1 && !_scaling) {
      _pageDrag?.cancel();
      _pageDrag = null;
      _pageController.jumpToPage(_currentIndex);
      setState(() => _scaling = true);
    }
    final zoomed = _transform.value.getMaxScaleOnAxis() > 1.01;
    if (_zoomed != zoomed) setState(() => _zoomed = zoomed);
    if (_zoomed || _scaling) return;
    final delta = details.focalPointDelta.dx;
    _pageDrag?.update(
      DragUpdateDetails(
        globalPosition: details.focalPoint,
        delta: Offset(delta, 0),
        primaryDelta: delta,
      ),
    );
  }

  void _onMediaInteractionEnd(ScaleEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    _pageDrag?.end(
      DragEndDetails(
        velocity: Velocity(pixelsPerSecond: Offset(velocity, 0)),
        primaryVelocity: velocity,
      ),
    );
    _pageDrag = null;
    if (details.pointerCount == 0) setState(() => _scaling = false);
  }

  Future<void> _retry(String messageId, String url) async {
    try {
      if (isPrivateMedia(url)) {
        await NetworkImage(url, headers: mediaAuthHeaders(url)).evict();
      } else {
        await CachedNetworkImage.evictFromCache(url);
      }
    } catch (_) {
      // Recreating the provider still retries when cache eviction is unavailable.
    } finally {
      if (mounted) {
        setState(() {
          _retryAttempts.update(
            messageId,
            (attempt) => attempt + 1,
            ifAbsent: () => 1,
          );
        });
      }
    }
  }

  MessageEntity get _current => _messages[_currentIndex];

  Future<void> _star() async {
    final message = _current;
    setState(() => _busy = true);
    final result = await ref
        .read(chatRepositoryProvider)
        .toggleStar(message.conversationId, message.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
      starred,
    ) {
      ref
          .read(conversationMessagesProvider(message.conversationId).notifier)
          .setStarred(message.id, starred);
    });
  }

  Future<void> _pin() async {
    final message = _current;
    setState(() => _busy = true);
    final result = await ref
        .read(chatRepositoryProvider)
        .setMessagePinned(
          message.conversationId,
          message.id,
          message.metadata?['pinned'] != true,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
      pinned,
    ) {
      setState(() {
        final index = _messages.indexWhere((item) => item.id == message.id);
        if (index >= 0) {
          _messages[index] = message.copyWith(
            metadata: {...?message.metadata, 'pinned': pinned},
          );
        }
      });
      unawaited(
        ref
            .read(conversationMessagesProvider(message.conversationId).notifier)
            .refresh(),
      );
    });
  }

  Future<void> _react() async {
    final message = _current;
    final emoji = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final emoji in ['❤️', '😂', '😮', '😢', '😡', '👍'])
              TextButton(
                onPressed: () => Navigator.pop(context, emoji),
                child: Text(emoji, style: AppTypography.h2),
              ),
          ],
        ),
      ),
    );
    if (emoji == null || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(chatRepositoryProvider)
        .reactToMessage(message.conversationId, message.id, emoji);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
      reactions,
    ) {
      ref
          .read(conversationMessagesProvider(message.conversationId).notifier)
          .applyReactions(message.id, reactions);
      setState(() {
        final index = _messages.indexWhere((item) => item.id == message.id);
        if (index >= 0) {
          _messages[index] = message.copyWith(reactions: reactions);
        }
      });
    });
  }

  Future<void> _delete() async {
    final message = _current;
    if (message.senderId != ref.read(authControllerProvider).value?.id) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).chatDelete),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n(context).chatConfirmDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final result = await ref
        .read(chatRepositoryProvider)
        .deleteMessage(message.conversationId, message.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold((failure) => AppSnackbar.handleFailure(context, failure), (_) {
      ref
          .read(conversationMessagesProvider(message.conversationId).notifier)
          .removeByIds({message.id});
      ref.invalidate(liveChatListProvider);
      widget.onDeleted?.call(message.id);
      _videoGeneration++;
      unawaited(_disposeVideo());
      setState(() {
        _messages.removeWhere((item) => item.id == message.id);
        _currentIndex = _messages.isEmpty
            ? 0
            : _currentIndex.clamp(0, _messages.length - 1);
        _videoError = null;
        _zoomed = false;
        _transform.value = Matrix4.identity();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _messages.isEmpty) return;
        _pageController.jumpToPage(_currentIndex);
        unawaited(_loadCurrentVideo());
      });
    });
  }

  Future<void> _save() async {
    final message = _current;
    setState(() => _busy = true);
    File? temporary;
    try {
      final url = mediaUrl(message.attachmentUrl!);
      final headers = await getMediaAuthHeadersAsync(url);
      final response = await HttpClient.instance.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) throw StateError('Empty media');
      final gallery = MediaGalleryService();
      if (message.type == MessageType.video) {
        final directory = await getTemporaryDirectory();
        temporary = File(
          '${directory.path}/chat-save-${DateTime.now().microsecondsSinceEpoch}.mp4',
        );
        await temporary.writeAsBytes(bytes, flush: true);
        await gallery.saveVideo(temporary.path);
      } else {
        await gallery.saveImage(Uint8List.fromList(bytes));
      }
      if (mounted) {
        AppSnackbar.success(context, l10n(context).mediaEditorSavedToDevice);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, l10n(context).mediaEditorSaveFailed);
      }
    } finally {
      if (temporary != null && await temporary.exists()) {
        await temporary.delete();
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  void _info() {
    final message = _current;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n(context).chatMediaInfo),
        content: Text(
          '${message.createdAt.toLocal()}${message.content?.isNotEmpty == true ? '\n${message.content}' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n(context).commonClose),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    final strings = l10n(context);
    final message = _current;
    final starred = ref.watch(
      conversationMessagesProvider(
        message.conversationId,
      ).select((state) => state.starredIds.contains(message.id)),
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          IconButton(
            tooltip: strings.chatReply,
            icon: const Icon(Icons.reply),
            onPressed: _busy || widget.onReply == null
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onReply!(message);
                  },
          ),
          IconButton(
            tooltip: starred ? strings.chatRemoveStarred : strings.chatFavorite,
            icon: Icon(starred ? Icons.star : Icons.star_border),
            onPressed: _busy ? null : _star,
          ),
          IconButton(
            tooltip: message.metadata?['pinned'] == true
                ? strings.chatUnpin
                : strings.chatPin,
            icon: Icon(
              message.metadata?['pinned'] == true
                  ? Icons.push_pin
                  : Icons.push_pin_outlined,
            ),
            onPressed: _busy ? null : _pin,
          ),
          IconButton(
            tooltip: strings.chatReact,
            icon: const Icon(Icons.add_reaction_outlined),
            onPressed: _busy ? null : _react,
          ),
          if (message.senderId == ref.watch(authControllerProvider).value?.id)
            IconButton(
              tooltip: strings.chatDelete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
          IconButton(
            tooltip: strings.chatForward,
            icon: const Icon(Icons.forward),
            onPressed: _busy
                ? null
                : () => showForwardMessageSheet(
                    context: context,
                    messageIds: [message.id],
                    currentChatId: message.conversationId,
                  ),
          ),
          PopupMenuButton<String>(
            tooltip: strings.chatMore,
            enabled: !_busy,
            onSelected: (action) {
              if (action == 'save') {
                unawaited(_save());
              } else {
                _info();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'info', child: Text(strings.chatMediaInfo)),
              PopupMenuItem(value: 'save', child: Text(strings.commonSave)),
            ],
          ),
          IconButton(
            tooltip: strings.commonClose,
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_messages.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surfaceContainerDark,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n(context).chatMediaUnavailable),
                AppButton(
                  label: l10n(context).commonClose,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerDark,
      body: SafeArea(
        child: Column(
          children: [
            IconTheme(
              data: const IconThemeData(color: AppColors.onSurfaceDark),
              child: _toolbar(),
            ),
            if (_busy) const LinearProgressIndicator(),
            // Main media viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _messages.length,
                onPageChanged: _onPageChanged,
                physics: _zoomed || _scaling
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isVideo = message.type == MessageType.video;
                  final url = mediaUrl(message.attachmentUrl!);

                  return InteractiveViewer(
                    key: ValueKey(message.id),
                    transformationController: index == _currentIndex
                        ? _transform
                        : null,
                    panEnabled: _zoomed,
                    onInteractionStart: _onMediaInteractionStart,
                    onInteractionUpdate: _onMediaInteractionUpdate,
                    onInteractionEnd: _onMediaInteractionEnd,
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: ColoredBox(color: context.surfaceMidColor),
                        ),
                        isVideo && index == _currentIndex
                            ? _buildVideo()
                            : isVideo
                            ? _thumbnailFallback(context, true)
                            : isPrivateMedia(url)
                            ? Image.network(
                                url,
                                key: ValueKey(
                                  'gallery-${message.id}-${_retryAttempts[message.id] ?? 0}',
                                ),
                                headers: mediaAuthHeaders(url),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null
                                    ? child
                                    : _thumbnailLoading(context),
                                errorBuilder: (context, error, stackTrace) =>
                                    _mediaError(context, message, url),
                              )
                            : CachedNetworkImage(
                                imageUrl: url,
                                key: ValueKey(
                                  'gallery-${message.id}-${_retryAttempts[message.id] ?? 0}',
                                ),
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) =>
                                    _thumbnailLoading(context),
                                errorWidget: (context, url, error) =>
                                    _mediaError(context, message, url),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: l10n(context).chatPreviousMedia,
                  icon: const Icon(
                    Icons.chevron_left,
                    color: AppColors.onSurfaceDark,
                  ),
                  onPressed: _currentIndex > 0
                      ? () => _onThumbnailTap(_currentIndex - 1)
                      : null,
                ),
                Text(
                  '${_currentIndex + 1} / ${_messages.length}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.onSurfaceDark,
                  ),
                ),
                IconButton(
                  tooltip: l10n(context).chatNextMedia,
                  icon: const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceDark,
                  ),
                  onPressed: _currentIndex + 1 < _messages.length
                      ? () => _onThumbnailTap(_currentIndex + 1)
                      : null,
                ),
              ],
            ),
            // Bottom thumbnail strip
            Container(
              height: Spacing.lg * 4,
              padding: const EdgeInsets.symmetric(
                vertical: Spacing.md - Spacing.xs,
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isActive = index == _currentIndex;
                  final url = mediaUrl(message.attachmentUrl!);
                  final isVideo = message.type == MessageType.video;

                  return GestureDetector(
                    onTap: () => _onThumbnailTap(index),
                    child: Container(
                      width: Spacing.lg * 3,
                      height: Spacing.lg * 3,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isActive
                              ? AppColors.primaryContainer
                              : AppColors.onSurfaceDark.withAlpha(61),
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: _thumbnailFallback(context, isVideo),
                          ),
                          isVideo
                              ? _thumbnailFallback(context, true)
                              : isPrivateMedia(url)
                              ? Image.network(
                                  url,
                                  headers: mediaAuthHeaders(url),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  loadingBuilder: (context, child, progress) =>
                                      progress == null
                                      ? child
                                      : _thumbnailLoading(context),
                                  errorBuilder: (context, error, stackTrace) =>
                                      _thumbnailFallback(context, isVideo),
                                )
                              : CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) =>
                                      _thumbnailLoading(context),
                                  errorWidget: (context, url, error) =>
                                      _thumbnailFallback(context, isVideo),
                                ),
                          if (isVideo)
                            const Icon(
                              Icons.play_arrow,
                              color: AppColors.onSurfaceDark,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (_videoError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _videoError!,
              style: const TextStyle(color: AppColors.onSurfaceDark),
            ),
            AppButton(
              label: l10n(context).commonRetry,
              onPressed: _loadCurrentVideo,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      );
    }
    if (controller?.value.isInitialized != true) {
      return const Center(child: CircularProgressIndicator());
    }
    return GestureDetector(
      onTap: () {
        final video = _videoController;
        if (video == null) return;
        if (video.value.isPlaying) {
          video.pause();
        } else {
          video.play();
        }
        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
          if (!controller.value.isPlaying)
            const Icon(
              Icons.play_arrow,
              color: AppColors.onSurfaceDark,
              size: 56,
            ),
        ],
      ),
    );
  }

  Widget _mediaError(BuildContext context, MessageEntity message, String url) =>
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_outlined, color: context.textSecondary),
            const SizedBox(height: 8),
            Text(
              l10n(context).chatMediaUnavailable,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppButton(
              onPressed: () => _retry(message.id, url),
              label: l10n(context).commonRetry,
              icon: Icons.refresh,
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      );

  Widget _thumbnailFallback(BuildContext context, bool isVideo) => ColoredBox(
    color: context.surfaceMidColor,
    child: Center(
      child: Icon(
        isVideo ? Icons.play_circle_outline : Icons.image_outlined,
        color: context.textSecondary,
      ),
    ),
  );

  Widget _thumbnailLoading(BuildContext context) => ColoredBox(
    color: context.surfaceMidColor,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, color: context.textSecondary),
          const SizedBox(height: Spacing.sm),
          const SizedBox(
            width: Spacing.md + Spacing.xs,
            height: Spacing.md + Spacing.xs,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    ),
  );
}
