import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Full-screen viewer for a local file image with zoom + edit button.
class LocalImageFullScreen extends StatefulWidget {
  final String path;
  final VoidCallback onEdit;

  const LocalImageFullScreen({
    super.key,
    required this.path,
    required this.onEdit,
  });

  @override
  State<LocalImageFullScreen> createState() => _LocalImageFullScreenState();
}

class _LocalImageFullScreenState extends State<LocalImageFullScreen> {
  final _transformController = TransformationController();

  bool get _isZoomed => _transformController.value != Matrix4.identity();

  void _onDoubleTapDown(TapDownDetails details) {
    if (_isZoomed) {
      _transformController.value = Matrix4.identity();
    } else {
      final pos = details.localPosition;
      _transformController.value = Matrix4.identity()
        ..translateByDouble(-pos.dx * 2, -pos.dy * 2, 0, 1)
        ..scaleByDouble(3.0, 3.0, 3.0, 1);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: _onDoubleTapDown,
            onDoubleTap: () {},
            child: InteractiveViewer(
              transformationController: _transformController,
              maxScale: 6,
              child: Center(
                child: Image.file(File(widget.path), fit: BoxFit.contain),
              ),
            ),
          ),
          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: AppColors.onSurface.withValues(alpha: 0.7),
                        child: Semantics(
                          button: true,
                          label: strings.accessibilityClose,
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        color: AppColors.primaryContainer,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              strings.commonEdit.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Hint
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                color: Colors.black54,
                child: Text(
                  strings.imageDoubleTapToZoom,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with image source options.
class ImageOptionsSheet extends StatelessWidget {
  final bool hasImage;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback? onView;
  final VoidCallback? onRemove;

  const ImageOptionsSheet({
    super.key,
    required this.hasImage,
    required this.onPickGallery,
    required this.onPickCamera,
    this.onView,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final fg = context.textPrimary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SheetTile(
          icon: Icons.photo_library_outlined,
          label: hasImage
              ? strings.imageReplaceFromGallery
              : strings.imageAddFromGallery,
          color: fg,
          onTap: onPickGallery,
        ),
        SheetTile(
          icon: Icons.camera_alt_outlined,
          label: hasImage
              ? strings.imageReplaceFromCamera
              : strings.imageAddFromCamera,
          color: fg,
          onTap: onPickCamera,
        ),
        if (onView != null)
          SheetTile(
            icon: Icons.zoom_in,
            label: strings.feedInspectImage,
            color: fg,
            onTap: onView!,
          ),
        if (onRemove != null)
          SheetTile(
            icon: Icons.delete_outline,
            label: strings.feedRemoveImage,
            color: AppColors.error,
            onTap: onRemove!,
          ),
      ],
    );
  }
}

class SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const SheetTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: color,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
