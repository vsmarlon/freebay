import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_models.dart';
import 'package:freebay/features/media_editor/presentation/widgets/image_editor_paint.dart';
import 'package:freebay/features/chat/presentation/widgets/view_once_toggle.dart';
import 'package:freebay/features/media_editor/presentation/widgets/color_filters.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

/// Discard-confirmation dialog for the image editor.
void showDiscardEditorDialog(
  BuildContext context, {
  required VoidCallback onDiscard,
}) {
  final strings = l10n(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      backgroundColor: context.surfaceColor,
      title: Text(
        strings.chatEditorDiscardChangesTitle,
        style: AppTypography.h3,
      ),
      content: Text(
        strings.chatEditorDiscardChangesBody,
        style: AppTypography.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            strings.commonCancel.toUpperCase(),
            style: AppTypography.button,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDiscard();
          },
          child: Text(
            strings.chatEditorDiscard.toUpperCase(),
            style: AppTypography.button.copyWith(color: AppColors.error),
          ),
        ),
      ],
    ),
  );
}

/// Crop step of the image editor.
class EditorCropView extends StatefulWidget {
  const EditorCropView({
    super.key,
    required this.imageBytes,
    required this.cropController,
    required this.isCropping,
    required this.onCropped,
  });

  final Uint8List imageBytes;
  final CropController cropController;
  final bool isCropping;
  final ValueChanged<Uint8List?> onCropped;

  @override
  State<EditorCropView> createState() => _EditorCropViewState();
}

class _EditorCropViewState extends State<EditorCropView> {
  double? _aspectRatio;

  void _setAspectRatio(double? ratio) {
    setState(() => _aspectRatio = ratio);
    widget.cropController.aspectRatio = ratio;
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Crop(
                image: widget.imageBytes,
                controller: widget.cropController,
                onCropped: (result) {
                  if (result is CropSuccess) {
                    widget.onCropped(result.croppedImage);
                  } else {
                    widget.onCropped(null);
                  }
                },
                aspectRatio: _aspectRatio,
                maskColor: Colors.black54,
                baseColor: Colors.black,
              ),
              if (widget.isCropping)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
            ],
          ),
        ),
        Container(
          color: context.surfaceColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _AspectRatioButton(
                  label: strings.chatEditorCropFree,
                  isSelected: _aspectRatio == null,
                  onTap: () => _setAspectRatio(null),
                ),
                const SizedBox(width: 8),
                _AspectRatioButton(
                  label: '1:1',
                  isSelected: _aspectRatio == 1.0,
                  onTap: () => _setAspectRatio(1.0),
                ),
                const SizedBox(width: 8),
                _AspectRatioButton(
                  label: '4:3',
                  isSelected: _aspectRatio == 4 / 3,
                  onTap: () => _setAspectRatio(4 / 3),
                ),
                const SizedBox(width: 8),
                _AspectRatioButton(
                  label: '3:4',
                  isSelected: _aspectRatio == 3 / 4,
                  onTap: () => _setAspectRatio(3 / 4),
                ),
                const SizedBox(width: 8),
                _AspectRatioButton(
                  label: '16:9',
                  isSelected: _aspectRatio == 16 / 9,
                  onTap: () => _setAspectRatio(16 / 9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AspectRatioButton extends StatelessWidget {
  const _AspectRatioButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected
            ? AppColors.primaryContainer
            : context.surfaceHighColor,
        child: Text(
          label,
          style: AppTypography.button.copyWith(
            color: isSelected ? AppColors.onPrimary : context.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Canvas view supporting drawing, text overlays, filters, adjustments, and rotation.
class EditorCanvasView extends StatelessWidget {
  const EditorCanvasView({
    super.key,
    required this.decodedImageFuture,
    required this.strokes,
    required this.activePoints,
    required this.drawColor,
    required this.drawWidth,
    required this.penStyle,
    required this.onCanvasSize,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.filterMatrix,
    required this.rotationAngle,
    required this.textOverlays,
  });

  final Future<ui.Image>? decodedImageFuture;
  final List<DrawStroke> strokes;
  final List<Offset>? activePoints;
  final Color drawColor;
  final double drawWidth;
  final PenStyle penStyle;
  final ValueChanged<Size> onCanvasSize;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final ValueChanged<DragEndDetails> onPanEnd;

  // New properties for adjustments and filters
  final double brightness;
  final double contrast;
  final double saturation;
  final List<double> filterMatrix;
  final double rotationAngle;
  final List<TextOverlay> textOverlays;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        onCanvasSize(constraints.biggest);
        return GestureDetector(
          onPanStart: (details) => onPanStart(details.localPosition),
          onPanUpdate: (details) => onPanUpdate(details.localPosition),
          onPanEnd: onPanEnd,
          child: FutureBuilder<ui.Image>(
            future: decodedImageFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final image = snapshot.data!;
              final imageSize = Size(
                image.width.toDouble(),
                image.height.toDouble(),
              );
              final fittedSizes = applyBoxFit(
                BoxFit.contain,
                imageSize,
                constraints.biggest,
              );
              final destination = Alignment.center.inscribe(
                fittedSizes.destination,
                Offset.zero & constraints.biggest,
              );

              // Build the base image painter
              Widget content = CustomPaint(
                painter: ImagePainter(image, destination),
                foregroundPainter: DrawPainter(
                  strokes,
                  activePoints,
                  drawColor,
                  drawWidth,
                  penStyle,
                ),
                size: constraints.biggest,
              );

              // Apply rotation
              if (rotationAngle != 0) {
                content = Transform.rotate(
                  angle: rotationAngle,
                  child: content,
                );
              }

              // Apply color filters
              content = ColorFiltered(
                colorFilter: ColorFilter.matrix(filterMatrix),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    ColorFilterMatrices.brightness(brightness),
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      ColorFilterMatrices.contrast(contrast),
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        ColorFilterMatrices.saturation(saturation),
                      ),
                      child: content,
                    ),
                  ),
                ),
              );

              // Stack text overlays on top
              if (textOverlays.isNotEmpty) {
                content = Stack(
                  children: [
                    content,
                    ...textOverlays.map((overlay) {
                      return Positioned(
                        left: overlay.position.dx,
                        top: overlay.position.dy,
                        child: Text(
                          overlay.text,
                          style: AppTypography.h1.copyWith(
                            color: overlay.color,
                            fontSize: overlay.fontSize,
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }

              return content;
            },
          ),
        );
      },
    );
  }
}

/// Caption + view-once step of the image editor.
class EditorPreviewView extends StatelessWidget {
  const EditorPreviewView({
    super.key,
    required this.imageBytes,
    required this.coverFit,
    required this.captionController,
    required this.showViewOnce,
    required this.viewOnce,
    required this.onViewOnceToggle,
  });

  final Uint8List imageBytes;
  final bool coverFit;
  final TextEditingController captionController;
  final bool showViewOnce;
  final bool viewOnce;
  final VoidCallback onViewOnceToggle;

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.memory(
              imageBytes,
              width: double.infinity,
              fit: coverFit ? BoxFit.cover : BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: captionController,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: strings.chatImageCaption,
              hintStyle: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: Colors.white70, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: AppColors.primaryContainer,
                  width: 2,
                ),
              ),
            ),
          ),
          if (showViewOnce) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ViewOnceToggle(enabled: viewOnce, onTap: onViewOnceToggle),
            ),
          ],
        ],
      ),
    );
  }
}
