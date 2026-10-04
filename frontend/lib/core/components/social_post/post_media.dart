import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/components/blur_hash_placeholder.dart';
import 'package:freebay/shared/utils/media_url.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class SocialPostMedia extends StatelessWidget {
  final String? imageUrl;
  final String? blurHash;
  final bool showHeartBurst;
  final bool isPressed;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<bool> onPressedChanged;
  final Widget? priceTag;

  const SocialPostMedia({
    super.key,
    required this.imageUrl,
    this.blurHash,
    required this.showHeartBurst,
    required this.isPressed,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPressedChanged,
    required this.priceTag,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final decodeWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context))
            .ceil()
            .clamp(1, 1080);
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPressStart: (_) => onPressedChanged(true),
            onLongPressEnd: (_) => onPressedChanged(false),
            child: AnimatedContainer(
              duration: AppMotion.base,
              transform: isPressed
                  ? (Matrix4.identity()
                      ..setEntry(0, 0, 1.02)
                      ..setEntry(1, 1, 1.02))
                  : Matrix4.identity(),
              color: context.surfaceMidColor,
              child: imageUrl != null
                  ? isPrivateMedia(imageUrl!)
                        ? Image.network(
                            imageUrl!,
                            headers: mediaAuthHeaders(imageUrl!),
                            cacheWidth: decodeWidth,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, _, _) =>
                                Icon(Icons.image, color: context.textSecondary),
                          )
                        : CachedNetworkImage(
                            imageUrl: imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: decodeWidth,
                            placeholder: (context, url) => BlurHashPlaceholder(
                              hash: blurHash,
                              fallback: Container(
                                color: context.surfaceMidColor,
                              ),
                            ),
                            errorWidget: (context, error, stackTrace) =>
                                Container(
                                  color: context.surfaceMidColor,
                                  child: Icon(
                                    Icons.image,
                                    color: context.textSecondary,
                                    size: 48,
                                  ),
                                ),
                          )
                  : Center(
                      child: Text(
                        strings.productForSaleBadge,
                        style: AppTypography.h2.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ),
            ),
          ),
          if (showHeartBurst)
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
          if (priceTag != null)
            Positioned(bottom: 12, right: 12, child: priceTag!),
        ],
      ),
    );
  }
}
