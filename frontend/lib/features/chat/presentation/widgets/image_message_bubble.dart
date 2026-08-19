import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/core/components/full_screen_image_viewer.dart';

class ImageMessageBubble extends StatelessWidget {
  final String? imageUrl;
  final bool isMe;

  const ImageMessageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
  });

  String? get _fullUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    final url = imageUrl!;
    if (url.startsWith('http')) return url;
    return '${AppConfig.apiBaseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    final url = _fullUrl;
    if (url == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => showFullScreenImage(context, url),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240, maxHeight: 300),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 200,
            height: 150,
            color: isMe
                ? Colors.white.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            width: 200,
            height: 150,
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Icon(Icons.broken_image, size: 32),
          ),
        ),
      ),
    );
  }
}
