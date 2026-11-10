import 'dart:async';

import 'package:freebay/core/ui.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ImageMessageBubble extends StatefulWidget {
  final String? imageUrl;
  final bool isMe;

  final VoidCallback? onTapImage;
  final String? viewOnceOpeningKey;

  const ImageMessageBubble({
    super.key,
    required this.imageUrl,
    required this.isMe,
    this.onTapImage,
    this.viewOnceOpeningKey,
  });

  @override
  State<ImageMessageBubble> createState() => _ImageMessageBubbleState();
}

class _ImageMessageBubbleState extends State<ImageMessageBubble> {
  int _attempt = 0;

  String? get _fullUrl {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) return null;
    return mediaUrl(widget.imageUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final url = _fullUrl;
    if (url == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.viewOnceOpeningKey != null
          ? null
          : widget.onTapImage ??
                () => unawaited(showAppImageViewer(context, url)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240, maxHeight: 300),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            isPrivateMedia(url)
                ? Image.network(
                    url,
                    headers: mediaAuthHeaders(
                      url,
                      viewOnceOpeningKey: widget.viewOnceOpeningKey,
                    ),
                    fit: BoxFit.cover,
                    key: ValueKey(_attempt),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _loading(context),
                    errorBuilder: (context, error, stackTrace) =>
                        _error(context),
                  )
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    key: ValueKey(_attempt),
                    memCacheWidth: 600,
                    memCacheHeight: 800,
                    placeholder: (context, url) => _loading(context),
                    errorWidget: (context, url, error) => _error(context),
                  ),
            if (widget.viewOnceOpeningKey != null)
              Positioned(
                top: 8,
                left: 8,
                child: ColoredBox(
                  color: context.colors.surface.withValues(alpha: 0.9),
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xs),
                    child: Text(
                      l10n(context).chatViewOnceExpiresOnClose,
                      style: AppTypography.labelSmall,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _error(BuildContext context) => SizedBox(
    width: 200,
    height: 150,
    child: ColoredBox(
      color: context.surfaceMidColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: context.textSecondary),
          const SizedBox(height: 4),
          Text(
            widget.isMe
                ? l10n(context).chatMediaUnavailableSender
                : l10n(context).chatMediaUnavailable,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
          AppButton(
            onPressed: _retry,
            icon: Icons.refresh,
            label: l10n(context).commonRetry,
            variant: AppButtonVariant.secondary,
          ),
        ],
      ),
    ),
  );

  Widget _loading(BuildContext context) => SizedBox(
    width: 200,
    height: 150,
    child: ColoredBox(
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
    ),
  );

  Future<void> _retry() async {
    final url = _fullUrl;
    if (url == null) return;
    try {
      if (isPrivateMedia(url)) {
        await NetworkImage(
          url,
          headers: mediaAuthHeaders(
            url,
            viewOnceOpeningKey: widget.viewOnceOpeningKey,
          ),
        ).evict();
      } else {
        await CachedNetworkImage.evictFromCache(url);
      }
    } catch (_) {
      // Recreating the provider still retries when cache eviction is unavailable.
    } finally {
      if (mounted) setState(() => _attempt++);
    }
  }
}
