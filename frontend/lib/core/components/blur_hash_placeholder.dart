import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/shared/entities/uploaded_media.dart';

class BlurHashPlaceholder extends StatelessWidget {
  final String? hash;
  final BoxFit fit;
  final Widget? fallback;

  const BlurHashPlaceholder({
    super.key,
    required this.hash,
    this.fit = BoxFit.cover,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final value = hash;
    if (value == null || !UploadedMedia.isValidBlurHash(value)) {
      return fallback ?? ColoredBox(color: context.surfaceColor);
    }
    return BlurHash(hash: value, imageFit: fit, color: context.surfaceColor);
  }
}
