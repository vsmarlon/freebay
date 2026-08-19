import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';

/// Infinite-scroll grid of images fetched from the conversation media endpoint.
///
/// Pass the initial list of messages (already in scope from the details page)
/// and a [onLoadMore] callback that fetches the next page via the repository.
class MediaGrid extends StatefulWidget {
  final String conversationId;
  final List<MessageEntity> initialMessages;
  final Future<List<MessageEntity>> Function(String? cursor) onLoadMore;

  const MediaGrid({
    super.key,
    required this.conversationId,
    required this.initialMessages,
    required this.onLoadMore,
  });

  @override
  State<MediaGrid> createState() => _MediaGridState();
}

class _MediaGridState extends State<MediaGrid> {
  final _scrollController = ScrollController();
  final List<MessageEntity> _messages = [];
  String? _cursor;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _firstLoad = true;

  @override
  void initState() {
    super.initState();
    _messages.addAll(widget.initialMessages);
    _firstLoad = _messages.isEmpty;
    _scrollController.addListener(_onScroll);
    if (_firstLoad) _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final results = await widget.onLoadMore(_cursor);
      setState(() {
        _messages.addAll(results);
        _hasMore = results.isNotEmpty;
        _cursor = results.isNotEmpty ? results.last.id : _cursor;
        _firstLoad = false;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_firstLoad && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryContainer,
          strokeWidth: 2,
        ),
      );
    }

    if (!_firstLoad && _messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: context.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'NENHUMA MÍDIA',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Imagens enviadas aparecem aqui.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _messages.length + (_isLoading ? 3 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return Container(color: context.surfaceMidColor);
        }
        final msg = _messages[index];
        final imageUrl = msg.attachmentUrl;
        if (imageUrl == null || imageUrl.isEmpty) {
          return Container(color: context.surfaceMidColor);
        }
        return _MediaTile(imageUrl: imageUrl, message: msg);
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final String imageUrl;
  final MessageEntity message;

  const _MediaTile({required this.imageUrl, required this.message});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Full-screen view — push ChatImageViewer when available
        showDialog(
          context: context,
          useSafeArea: false,
          builder: (_) => _FullscreenImageDialog(imageUrl: imageUrl),
        );
      },
      child: Container(
        color: context.surfaceMidColor,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) {
            if (progress == null) return child;
            return Container(color: context.surfaceMidColor);
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: context.surfaceMidColor,
            child: const Icon(
              Icons.broken_image_outlined,
              color: AppColors.mediumGray,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenImageDialog extends StatelessWidget {
  final String imageUrl;

  const _FullscreenImageDialog({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.mediumGray,
                    size: 48,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
