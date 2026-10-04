import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/components/blur_hash_placeholder.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

/// Product image for [AppCard] with a branded placeholder fallback.
class AppCardImage extends StatelessWidget {
  const AppCardImage({
    super.key,
    required this.imageUrl,
    required this.height,
    this.blurHash,
  });

  final String? imageUrl;
  final double height;
  final String? blurHash;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _AppCardPlaceholder(height: height);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      memCacheHeight: 400,
      placeholder: (context, url) => BlurHashPlaceholder(
        hash: blurHash,
        fallback: _AppCardPlaceholder(height: height),
      ),
      errorWidget: (context, url, error) => _AppCardPlaceholder(height: height),
    );
  }
}

class _AppCardPlaceholder extends StatelessWidget {
  const _AppCardPlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.surfaceMidColor, context.surfaceHighColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primaryContainer,
              size: 32,
            ),
            SizedBox(height: 4),
            Text(
              'FREEBAY',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
