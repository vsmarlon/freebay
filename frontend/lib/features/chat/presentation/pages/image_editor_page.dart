import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_models.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_paint.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_toolbar.dart';
import 'package:freebay/features/chat/presentation/widgets/image_editor_views.dart';
import 'package:freebay/features/chat/presentation/widgets/color_filters.dart';
import 'package:go_router/go_router.dart';

class ImageEditorPage extends StatefulWidget {
  final Uint8List initialImageBytes;
  final ImageEditorPurpose purpose;
  final Future<bool> Function(ImageEditorResult result) onComplete;

  const ImageEditorPage({
    super.key,
    required this.initialImageBytes,
    required this.purpose,
    required this.onComplete,
  });

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  late Uint8List _currentImageBytes = widget.initialImageBytes;
  EditorMode _mode = EditorMode.crop;

  // Crop State
  final _cropController = CropController();
  bool _isCropping = false;

  // Adjust State
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _rotationAngle = 0.0;

  // Filter State
  List<double> _filterMatrix = ColorFilterMatrices.normal;

  // Text State
  final List<TextOverlay> _textOverlays = [];

  // Draw State
  final List<DrawStroke> _strokes = [];
  Color _drawColor = AppColors.primaryContainer;
  double _drawWidth = 8;
  PenStyle _penStyle = PenStyle.marker;
  List<Offset>? _activePoints;
  Size _canvasSize = Size.zero;
  Future<ui.Image>? _decodedImageFuture;

  // Preview State
  final _captionController = TextEditingController();
  bool _viewOnce = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  void _decodeImage() {
    _decodedImageFuture = _decodeImageBytes(_currentImageBytes).then((image) {
      _decodedImage?.dispose();
      _decodedImage = image;
      return image;
    });
  }

  ui.Image? _decodedImage;

  Future<ui.Image> _decodeImageBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  void dispose() {
    _captionController.dispose();
    _decodedImage?.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (_mode == EditorMode.crop) {
      setState(() => _isCropping = true);
      _cropController.crop();
    } else if (_mode != EditorMode.preview) {
      await _exportDrawing();
      setState(() {
        _mode = EditorMode.preview;
      });
    } else if (_mode == EditorMode.preview) {
      await _complete();
    }
  }

  void _handleClose() {
    showDiscardEditorDialog(context, onDiscard: () => context.pop());
  }

  Future<void> _exportDrawing() async {
    final bytes = await exportFinalImage(
      decodedImageFuture: _decodedImageFuture,
      canvasSize: _canvasSize,
      strokes: _strokes,
      activePoints: _activePoints,
      color: _drawColor,
      width: _drawWidth,
      style: _penStyle,
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      filterMatrix: _filterMatrix,
      rotationAngle: _rotationAngle,
      textOverlays: _textOverlays,
    );
    if (bytes != null && mounted) {
      setState(() {
        _currentImageBytes = bytes;
        _decodeImage(); // Update decoded image for preview
        _strokes.clear();
        _textOverlays.clear();
        _brightness = 0;
        _contrast = 1;
        _saturation = 1;
        _rotationAngle = 0;
        _filterMatrix = ColorFilterMatrices.normal;
      });
    }
  }

  Future<void> _complete() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final caption = _captionController.text.trim();
      final completed = await widget.onComplete(
        ImageEditorResult(
          imageBytes: _currentImageBytes,
          caption: caption.isEmpty ? null : caption,
          viewOnce: widget.purpose == ImageEditorPurpose.chat && _viewOnce,
        ),
      );
      if (completed && mounted) context.pop();
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Erro ao processar imagem');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  // --- Draw Helpers ---
  void _startStroke(Offset point) {
    if (_mode != EditorMode.draw) return;
    setState(() => _activePoints = [point]);
  }

  void _updateStroke(Offset point) {
    if (_mode != EditorMode.draw) return;
    setState(() => _activePoints = [...?_activePoints, point]);
  }

  void _finishStroke() {
    if (_mode != EditorMode.draw) return;
    if (_activePoints == null || _activePoints!.length < 2) return;
    setState(() {
      _strokes.add(
        DrawStroke(_activePoints!, _drawColor, _drawWidth, _penStyle),
      );
      _activePoints = null;
    });
  }

  void _undoDraw() => setState(_strokes.removeLast);
  void _clearDraw() => setState(_strokes.clear);

  void _addText() {
    setState(() {
      _textOverlays.add(
        const TextOverlay(
          text: 'NOVO TEXTO',
          position: Offset(50, 50),
          color: AppColors.primaryContainer,
          fontSize: 24,
        ),
      );
    });
  }

  Widget _buildAdjustPanel() {
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.brightness_6, size: 20, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _brightness,
                  min: -1.0,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _brightness = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.contrast, size: 20, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _contrast,
                  max: 2.0,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _contrast = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.color_lens, size: 20, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _saturation,
                  max: 2.0,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _saturation = v),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => setState(() => _rotationAngle -= math.pi / 2),
                icon: const Icon(Icons.rotate_left),
                label: const Text('-90°'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => setState(() => _rotationAngle += math.pi / 2),
                icon: const Icon(Icons.rotate_right),
                label: const Text('+90°'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.screen_rotation, size: 20, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _rotationAngle % (math.pi * 2),
                  min: -math.pi,
                  max: math.pi,
                  activeColor: AppColors.primaryContainer,
                  onChanged: (v) => setState(() => _rotationAngle = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    final filters = {
      'Normal': ColorFilterMatrices.normal,
      'Clarendon': ColorFilterMatrices.clarendon,
      'Gingham': ColorFilterMatrices.gingham,
      'Moon': ColorFilterMatrices.moon,
      'Lark': ColorFilterMatrices.lark,
      'Reyes': ColorFilterMatrices.reyes,
      'Juno': ColorFilterMatrices.juno,
    };

    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.entries.map((e) {
            final isSelected = _filterMatrix == e.value;
            return GestureDetector(
              onTap: () => setState(() => _filterMatrix = e.value),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : context.surfaceHighColor,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : context.borderColor,
                    width: AppDepth.borderThin,
                  ),
                ),
                child: Text(
                  e.key,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected
                        ? AppColors.onPrimary
                        : context.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTextPanel() {
    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.all(16),
      child: AppButton(
        label: 'ADICIONAR TEXTO',
        onPressed: _addText,
        variant: AppButtonVariant.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: _handleClose,
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.close, color: Colors.white),
          ),
        ),
        title: Text(
          _mode == EditorMode.crop
              ? 'CORTAR'
              : _mode == EditorMode.adjust
              ? 'AJUSTES'
              : _mode == EditorMode.filter
              ? 'FILTROS'
              : _mode == EditorMode.text
              ? 'TEXTO'
              : _mode == EditorMode.draw
              ? 'DESENHAR'
              : 'PREVIEW',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          if (_mode == EditorMode.draw) ...[
            GestureDetector(
              onTap: _strokes.isEmpty ? null : _undoDraw,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.undo,
                  color: _strokes.isEmpty ? Colors.white38 : Colors.white,
                ),
              ),
            ),
            GestureDetector(
              onTap: _strokes.isEmpty ? null : _clearDraw,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.delete_outline,
                  color: _strokes.isEmpty ? Colors.white38 : Colors.white,
                ),
              ),
            ),
          ],
          GestureDetector(
            onTap: _isBusy || _isCropping ? null : _handleConfirm,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check, color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: switch (_mode) {
                EditorMode.crop => EditorCropView(
                  imageBytes: _currentImageBytes,
                  cropController: _cropController,
                  isCropping: _isCropping,
                  onCropped: (bytes) {
                    if (bytes == null) {
                      setState(() => _isCropping = false);
                      return;
                    }
                    setState(() {
                      _currentImageBytes = bytes;
                      _decodeImage();
                      _isCropping = false;
                      _mode = EditorMode.adjust;
                    });
                  },
                ),
                EditorMode.adjust ||
                EditorMode.filter ||
                EditorMode.text ||
                EditorMode.draw => EditorCanvasView(
                  decodedImageFuture: _decodedImageFuture,
                  strokes: _strokes,
                  activePoints: _activePoints,
                  drawColor: _drawColor,
                  drawWidth: _drawWidth,
                  penStyle: _penStyle,
                  brightness: _brightness,
                  contrast: _contrast,
                  saturation: _saturation,
                  filterMatrix: _filterMatrix,
                  rotationAngle: _rotationAngle,
                  textOverlays: _textOverlays,
                  onCanvasSize: (size) => _canvasSize = size,
                  onPanStart: _startStroke,
                  onPanUpdate: _updateStroke,
                  onPanEnd: (_) => _finishStroke(),
                ),
                EditorMode.preview => EditorPreviewView(
                  imageBytes: _currentImageBytes,
                  coverFit: widget.purpose == ImageEditorPurpose.story,
                  captionController: _captionController,
                  showViewOnce: widget.purpose == ImageEditorPurpose.chat,
                  viewOnce: _viewOnce,
                  onViewOnceToggle: () =>
                      setState(() => _viewOnce = !_viewOnce),
                ),
              },
            ),
            if (_mode == EditorMode.adjust) _buildAdjustPanel(),
            if (_mode == EditorMode.filter) _buildFilterPanel(),
            if (_mode == EditorMode.text) _buildTextPanel(),
            EditorToolbar(
              mode: _mode,
              penStyle: _penStyle,
              drawColor: _drawColor,
              drawWidth: _drawWidth,
              onTab: (mode) => setState(() => _mode = mode),
              onColor: (c) => setState(() {
                _drawColor = c;
                if (_penStyle == PenStyle.eraser) {
                  _penStyle = PenStyle.marker;
                }
              }),
              onPenStyle: (s) => setState(() => _penStyle = s),
              onWidth: (w) => setState(() => _drawWidth = w),
            ),
          ],
        ),
      ),
    );
  }
}
