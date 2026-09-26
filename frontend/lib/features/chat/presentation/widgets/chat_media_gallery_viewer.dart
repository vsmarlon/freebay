import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/data/entities/message_entity.dart';
import 'package:freebay/features/chat/data/entities/message_type.dart';
import 'package:freebay/shared/utils/media_url.dart';

class ChatMediaGalleryViewer extends StatefulWidget {
  final List<MessageEntity> mediaMessages;
  final int initialIndex;

  const ChatMediaGalleryViewer({
    super.key,
    required this.mediaMessages,
    required this.initialIndex,
  });

  static List<MessageEntity> extractMedia(List<MessageEntity> messages) {
    return messages.where((m) {
      if (m.deletedAt != null) return false;
      if (m.attachmentUrl == null || m.attachmentUrl!.isEmpty) return false;
      return m.type == MessageType.image ||
          m.type == MessageType.video ||
          m.type == MessageType.gif;
    }).toList();
  }

  @override
  State<ChatMediaGalleryViewer> createState() => _ChatMediaGalleryViewerState();
}

class _ChatMediaGalleryViewerState extends State<ChatMediaGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    HapticFeedback.selectionClick();
  }

  void _onThumbnailTap(int index) {
    _pageController.animateToPage(
      index,
      duration: AppMotion.tap,
      curve: AppMotion.baseCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    '${_currentIndex + 1} / ${widget.mediaMessages.length}',
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for close button
                ],
              ),
            ),
            // Main media viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.mediaMessages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final message = widget.mediaMessages[index];
                  final isVideo = message.type == MessageType.video;
                  final url = mediaUrl(message.attachmentUrl!);

                  return InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CachedNetworkImage(
                          imageUrl: url,
                          httpHeaders: mediaAuthHeaders(url),
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                        if (isVideo)
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom thumbnail strip
            Container(
              height: 64 + 32, // 64 for image + padding
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.mediaMessages.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final message = widget.mediaMessages[index];
                  final isActive = index == _currentIndex;
                  final url = mediaUrl(message.attachmentUrl!);
                  final isVideo = message.type == MessageType.video;

                  return GestureDetector(
                    onTap: () => _onThumbnailTap(index),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isActive
                              ? AppColors.primaryContainer
                              : Colors.white24,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CachedNetworkImage(
                            imageUrl: url,
                            httpHeaders: mediaAuthHeaders(url),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          if (isVideo)
                            const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
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
}
