import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_media_gallery_viewer.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/utils/media_url.dart';

typedef ConversationMediaPage = ({
  List<MessageEntity> messages,
  String? nextCursor,
});

class MediaGrid extends StatefulWidget {
  final String conversationId;
  final List<MessageEntity> initialMessages;
  final Future<ConversationMediaPage> Function(String? cursor) onLoadMore;
  final ValueChanged<MessageEntity> onReply;

  const MediaGrid({
    super.key,
    required this.conversationId,
    required this.initialMessages,
    required this.onLoadMore,
    required this.onReply,
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
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _merge(widget.initialMessages);
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void didUpdateWidget(covariant MediaGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    _merge(widget.initialMessages);
  }

  void _merge(List<MessageEntity> messages) {
    final byId = {for (final message in _messages) message.id: message};
    for (final message in ChatMediaGalleryViewer.extractMedia(messages)) {
      byId[message.id] = message;
    }
    _messages
      ..clear()
      ..addAll(byId.values)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 200) _load();
  }

  Future<void> _load() async {
    if (_isLoading || !_hasMore) return;
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    try {
      final page = await widget.onLoadMore(_cursor);
      if (!mounted) return;
      setState(() {
        _merge(page.messages);
        _hasMore = page.nextCursor != null && page.nextCursor != _cursor;
        _cursor = page.nextCursor;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _open(int index) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChatMediaGalleryViewer(
          mediaMessages: List.of(_messages),
          initialIndex: index,
          onReply: widget.onReply,
          onDeleted: (id) {
            if (mounted) {
              setState(
                () => _messages.removeWhere((message) => message.id == id),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty && !_failed) {
      return EmptyState(
        icon: Icons.photo_library_outlined,
        title: l10n(context).chatNoMedia,
        subtitle: l10n(context).chatMediaHint,
      );
    }
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              final video = message.type == MessageType.video;
              final thumbnail = video
                  ? (message.metadata?['thumbnailUrl'])
                  : message.attachmentUrl;
              final url = thumbnail is String && thumbnail.isNotEmpty
                  ? mediaUrl(thumbnail)
                  : null;
              return InkWell(
                key: ValueKey('media-${message.id}'),
                onTap: () => _open(index),
                child: ColoredBox(
                  color: context.surfaceMidColor,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (url != null)
                        Image.network(
                          url,
                          headers: mediaAuthHeaders(url),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Icon(
                            video
                                ? Icons.videocam_outlined
                                : Icons.broken_image_outlined,
                            color: context.textSecondary,
                          ),
                        ),
                      if (video)
                        const Center(
                          child: Icon(
                            Icons.play_circle_outline,
                            color: AppColors.onSurfaceDark,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_isLoading) const LinearProgressIndicator(),
        if (_failed || _hasMore && !_isLoading)
          TextButton(
            onPressed: _load,
            child: Text(
              _failed
                  ? l10n(context).commonRetry
                  : l10n(context).commonViewMore,
            ),
          ),
      ],
    );
  }
}
