import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/components/blur_hash_placeholder.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class SocialPostMediaItem {
  const SocialPostMediaItem({
    required this.url,
    this.thumbnailUrl,
    this.isVideo = false,
    this.blurHash,
  });

  final String url;
  final String? thumbnailUrl;
  final bool isVideo;
  final String? blurHash;
}

class SocialPostMedia extends StatefulWidget {
  final List<SocialPostMediaItem> media;
  final bool showHeartBurst;
  final bool isPressed;
  final double aspectRatio;
  final ValueChanged<SocialPostMediaItem> onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<bool> onPressedChanged;
  final Widget? priceTag;

  const SocialPostMedia({
    super.key,
    required this.media,
    required this.showHeartBurst,
    required this.isPressed,
    this.aspectRatio = 1,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPressedChanged,
    required this.priceTag,
  });

  @override
  State<SocialPostMedia> createState() => _SocialPostMediaState();
}

class _SocialPostMediaState extends State<SocialPostMedia> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void didUpdateWidget(SocialPostMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_index >= widget.media.length) {
      _index = widget.media.isEmpty ? 0 : widget.media.length - 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final decodeWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 1080);
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: [
          if (widget.media.isEmpty)
            ColoredBox(
              color: context.surfaceMidColor,
              child: Center(
                child: Text(
                  strings.productForSaleBadge,
                  style: AppTypography.h2.copyWith(
                    color: context.textSecondary,
                  ),
                ),
              ),
            )
          else
            PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                final item = widget.media[index];
                return GestureDetector(
                  onTap: () => widget.onTap(item),
                  onDoubleTap: widget.onDoubleTap,
                  onLongPressStart: (_) => widget.onPressedChanged(true),
                  onLongPressEnd: (_) => widget.onPressedChanged(false),
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    transform: widget.isPressed
                        ? (Matrix4.identity()
                            ..setEntry(0, 0, 1.02)
                            ..setEntry(1, 1, 1.02))
                        : Matrix4.identity(),
                    color: context.surfaceMidColor,
                    child: _MediaSlide(item: item, decodeWidth: decodeWidth),
                  ),
                );
              },
            ),
          if (widget.media.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: IgnorePointer(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < widget.media.length; index++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _index
                              ? AppColors.primaryContainer
                              : Colors.white70,
                          border: Border.all(color: Colors.black26),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (widget.showHeartBurst)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.2),
                duration: AppMotion.enter,
                curve: AppMotion.enterCurve,
                builder: (context, scale, child) => Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      border: Border.all(
                        color: AppColors.primaryContainer,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: AppColors.primaryContainer,
                      size: 64,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.priceTag != null)
            Positioned(bottom: 12, right: 12, child: widget.priceTag!),
        ],
      ),
    );
  }
}

class _MediaSlide extends StatelessWidget {
  const _MediaSlide({required this.item, required this.decodeWidth});

  final SocialPostMediaItem item;
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    if (!item.isVideo) {
      return _MediaImage(
        url: item.url,
        blurHash: item.blurHash,
        decodeWidth: decodeWidth,
      );
    }
    final thumbnailUrl = item.thumbnailUrl;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (thumbnailUrl != null)
          _MediaImage(
            url: thumbnailUrl,
            blurHash: item.blurHash,
            decodeWidth: decodeWidth,
          )
        else
          ColoredBox(color: context.surfaceMidColor),
        const Center(
          child: Icon(Icons.play_circle_fill, color: Colors.white70, size: 56),
        ),
      ],
    );
  }
}

class _MediaImage extends StatelessWidget {
  const _MediaImage({
    required this.url,
    required this.blurHash,
    required this.decodeWidth,
  });

  final String url;
  final String? blurHash;
  final int decodeWidth;

  @override
  Widget build(BuildContext context) {
    if (isPrivateMedia(url)) {
      return Image.network(
        url,
        headers: mediaAuthHeaders(url),
        cacheWidth: decodeWidth,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) =>
            Icon(Icons.image, color: context.textSecondary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: decodeWidth,
      placeholder: (context, url) => BlurHashPlaceholder(
        hash: blurHash,
        fallback: Container(color: context.surfaceMidColor),
      ),
      errorWidget: (context, error, stackTrace) => Container(
        color: context.surfaceMidColor,
        child: Icon(Icons.image, color: context.textSecondary, size: 48),
      ),
    );
  }
}
