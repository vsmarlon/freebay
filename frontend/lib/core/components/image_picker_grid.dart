import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/features/social/presentation/widgets/local_image_inspector.dart';

class ImagePickerGrid extends StatelessWidget {
  final List<File> images;
  final int maxImages;
  final ValueChanged<List<File>> onImagesChanged;

  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 5,
  });

  Future<void> _pickImage(BuildContext context) async {
    if (images.length >= maxImages) return;

    final source = await showBrutalistSheet<ImageSource>(
      context: context,
      title: 'OPÇÕES DE IMAGEM',
      builder: (ctx) => ImageOptionsSheet(
        hasImage: false,
        onPickGallery: () => Navigator.of(ctx).pop(ImageSource.gallery),
        onPickCamera: () => Navigator.of(ctx).pop(ImageSource.camera),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (picked != null) {
      onImagesChanged([...images, File(picked.path)]);
    }
  }

  void _openPreview(BuildContext context, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => LocalImageFullScreen(
          path: images[index].path,
          onEdit: () {
            Navigator.of(context).pop();
            _showEditOptions(context, index);
          },
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _showEditOptions(BuildContext context, int index) {
    showBrutalistSheet(
      context: context,
      title: 'OPÇÕES DE IMAGEM',
      builder: (ctx) => ImageOptionsSheet(
        hasImage: true,
        onPickGallery: () async {
          Navigator.pop(ctx);
          final picked = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (picked != null) {
            final updated = List<File>.from(images);
            updated[index] = File(picked.path);
            onImagesChanged(updated);
          }
        },
        onPickCamera: () async {
          Navigator.pop(ctx);
          final picked = await ImagePicker().pickImage(
            source: ImageSource.camera,
            maxWidth: 1920,
            maxHeight: 1920,
            imageQuality: 85,
          );
          if (picked != null) {
            final updated = List<File>.from(images);
            updated[index] = File(picked.path);
            onImagesChanged(updated);
          }
        },
        onRemove: () {
          Navigator.pop(ctx);
          final updated = List<File>.from(images)..removeAt(index);
          onImagesChanged(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length + (images.length < maxImages ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == images.length) {
            return GestureDetector(
              onTap: () => _pickImage(context),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  border: Border.all(color: context.borderColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: context.textSecondary,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${images.length}/$maxImages',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _openPreview(context, index),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.borderColor, width: 2),
                    image: DecorationImage(
                      image: FileImage(images[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: GestureDetector(
                  onTap: () {
                    final updated = List<File>.from(images)..removeAt(index);
                    onImagesChanged(updated);
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(color: AppColors.error),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
