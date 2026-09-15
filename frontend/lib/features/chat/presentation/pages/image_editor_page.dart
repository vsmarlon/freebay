import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/chat/presentation/widgets/view_once_toggle.dart';
import 'package:go_router/go_router.dart';

class ImageEditorResult {
  final Uint8List imageBytes;
  final String? caption;
  final bool viewOnce;

  const ImageEditorResult({
    required this.imageBytes,
    this.caption,
    required this.viewOnce,
  });
}

enum ImageEditorPurpose { chat, post, story }

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

enum _EditorMode { crop, draw, preview }

enum _PenStyle { marker, highlighter, eraser }

class _DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;
  final _PenStyle style;

  const _DrawStroke(this.points, this.color, this.width, this.style);
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  late Uint8List _currentImageBytes = widget.initialImageBytes;
  _EditorMode _mode = _EditorMode.crop;

  // Crop State
  final _cropController = CropController();
  bool _isCropping = false;

  // Draw State
  final List<_DrawStroke> _strokes = [];
  Color _drawColor = AppColors.primaryContainer;
  double _drawWidth = 8;
  _PenStyle _penStyle = _PenStyle.marker;
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
    if (_mode == _EditorMode.crop) {
      setState(() => _isCropping = true);
      _cropController.crop();
    } else if (_mode == _EditorMode.draw) {
      await _exportDrawing();
      setState(() {
        _mode = _EditorMode.preview;
      });
    } else if (_mode == _EditorMode.preview) {
      await _complete();
    }
  }

  void _handleClose() {
    // Show discard confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        backgroundColor: context.surfaceColor,
        title: const Text('DEScartar alterações?', style: AppTypography.h3),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCELAR', style: AppTypography.button),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: Text(
              'DESCARTAR',
              style: AppTypography.button.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDrawing() async {
    if (_decodedImageFuture == null) return;
    final image = await _decodedImageFuture!;
    final recorder = ui.PictureRecorder();

    // Fix 1: Use the original image dimensions for the recorder canvas
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    );
    canvas.drawImage(image, Offset.zero, Paint());

    // Fix 1: Handle scale and translation so strokes align
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final fittedSizes = applyBoxFit(BoxFit.contain, imageSize, _canvasSize);
    final destination = Alignment.center.inscribe(
      fittedSizes.destination,
      Offset.zero & _canvasSize,
    );

    final scaleX = image.width / destination.width;
    final scaleY = image.height / destination.height;

    canvas.scale(scaleX, scaleY);
    canvas.translate(-destination.left, -destination.top);

    _DrawPainter(
      _strokes,
      _activePoints,
      _drawColor,
      _drawWidth,
      _penStyle,
    ).drawStrokes(canvas);

    final result = await recorder.endRecording().toImage(
      image.width,
      image.height,
    );
    final data = await result.toByteData(format: ui.ImageByteFormat.png);
    result.dispose();
    if (data != null && mounted) {
      setState(() {
        _currentImageBytes = Uint8List.fromList(data.buffer.asUint8List());
        _decodeImage(); // Update decoded image for preview
        _strokes.clear();
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
    setState(() => _activePoints = [point]);
  }

  void _updateStroke(Offset point) {
    setState(() => _activePoints = [...?_activePoints, point]);
  }

  void _finishStroke() {
    if (_activePoints == null || _activePoints!.length < 2) return;
    setState(() {
      _strokes.add(
        _DrawStroke(_activePoints!, _drawColor, _drawWidth, _penStyle),
      );
      _activePoints = null;
    });
  }

  void _undoDraw() => setState(_strokes.removeLast);
  void _clearDraw() => setState(_strokes.clear);

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
          _mode == _EditorMode.crop
              ? 'CORTAR'
              : _mode == _EditorMode.draw
              ? 'DESENHAR'
              : 'PREVIEW',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          if (_mode == _EditorMode.draw) ...[
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
                _EditorMode.crop => _buildCropView(),
                _EditorMode.draw => _buildDrawView(),
                _EditorMode.preview => _buildPreviewView(),
              },
            ),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCropView() {
    return Stack(
      children: [
        Crop(
          image: _currentImageBytes,
          controller: _cropController,
          onCropped: (result) {
            if (result is CropSuccess) {
              setState(() {
                _currentImageBytes = result.croppedImage;
                _decodeImage();
                _isCropping = false;
                _mode = _EditorMode.draw; // Advance to draw
              });
            } else {
              setState(() => _isCropping = false);
            }
          },
          maskColor: Colors.black54,
          baseColor: Colors.black,
        ),
        if (_isCropping)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }

  Widget _buildDrawView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasSize = constraints.biggest;
        return GestureDetector(
          onPanStart: (details) => _startStroke(details.localPosition),
          onPanUpdate: (details) => _updateStroke(details.localPosition),
          onPanEnd: (_) => _finishStroke(),
          child: FutureBuilder<ui.Image>(
            future: _decodedImageFuture,
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
              // Fix 1: Calculate destination rect with applyBoxFit
              final fittedSizes = applyBoxFit(
                BoxFit.contain,
                imageSize,
                _canvasSize,
              );
              final destination = Alignment.center.inscribe(
                fittedSizes.destination,
                Offset.zero & _canvasSize,
              );

              return CustomPaint(
                painter: _ImagePainter(image, destination),
                foregroundPainter: _DrawPainter(
                  _strokes,
                  _activePoints,
                  _drawColor,
                  _drawWidth,
                  _penStyle,
                ),
                size: _canvasSize,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPreviewView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Image.memory(
              _currentImageBytes,
              width: double.infinity,
              fit: widget.purpose == ImageEditorPurpose.story
                  ? BoxFit.cover
                  : BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _captionController,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ADICIONAR LEGENDA',
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
          if (widget.purpose == ImageEditorPurpose.chat) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ViewOnceToggle(
                enabled: _viewOnce,
                onTap: () => setState(() => _viewOnce = !_viewOnce),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: context.surfaceColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_mode == _EditorMode.draw) _buildDrawPalette(),
          Row(
            children: [
              _buildTab(
                label: 'CROP',
                icon: Icons.crop,
                isSelected: _mode == _EditorMode.crop,
                onTap: () => setState(() => _mode = _EditorMode.crop),
              ),
              _buildTab(
                label: 'DRAW',
                icon: Icons.edit,
                isSelected: _mode == _EditorMode.draw,
                onTap: () => setState(() => _mode = _EditorMode.draw),
              ),
              _buildTab(
                label: 'PREVIEW',
                icon: Icons.preview,
                isSelected: _mode == _EditorMode.preview,
                onTap: () => setState(() => _mode = _EditorMode.preview),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawPalette() {
    // Brutalist horizontal scroll, 0px radius
    final colors = [
      AppColors.primaryContainer,
      Colors.white,
      Colors.black,
      const Color(0xFFE53935), // Red
      const Color(0xFF1E88E5), // Blue
      const Color(0xFF43A047), // Green
      const Color(0xFFFDD835), // Yellow
      const Color(0xFFFB8C00), // Orange
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: context.surfaceHighColor,
        border: Border(
          bottom: BorderSide(color: context.surfaceColor, width: 2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 8),
                ...colors.map(
                  (c) => GestureDetector(
                    onTap: () => setState(() {
                      _drawColor = c;
                      if (_penStyle == _PenStyle.eraser) {
                        _penStyle = _PenStyle.marker;
                      }
                    }),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: c,
                        border: Border.all(
                          color:
                              _drawColor == c && _penStyle != _PenStyle.eraser
                              ? context.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showColorPicker,
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      border: Border.all(color: context.textPrimary),
                    ),
                    child: Icon(
                      Icons.palette,
                      size: 18,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const SizedBox(width: 8),
                _buildToolBtn(
                  icon: Icons.edit,
                  isSelected: _penStyle == _PenStyle.marker,
                  onTap: () => setState(() => _penStyle = _PenStyle.marker),
                ),
                _buildToolBtn(
                  icon: Icons.brush,
                  isSelected: _penStyle == _PenStyle.highlighter,
                  onTap: () =>
                      setState(() => _penStyle = _PenStyle.highlighter),
                ),
                _buildToolBtn(
                  icon: Icons.cleaning_services,
                  isSelected: _penStyle == _PenStyle.eraser,
                  onTap: () => setState(() => _penStyle = _PenStyle.eraser),
                ),
                const SizedBox(width: 16),
                for (final width in [4.0, 8.0, 14.0, 24.0])
                  GestureDetector(
                    onTap: () => setState(() => _drawWidth = width),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: _drawWidth == width
                          ? context.surfaceColor
                          : Colors.transparent,
                      child: Center(
                        child: Container(
                          width: width > 16 ? 16 : width,
                          height: width > 16 ? 16 : width,
                          color: context.textPrimary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolBtn({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: isSelected ? context.textPrimary : Colors.transparent,
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? context.surfaceColor : context.textPrimary,
        ),
      ),
    );
  }

  void _showColorPicker() {
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final c = colors[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _drawColor = c;
                      if (_penStyle == _PenStyle.eraser) {
                        _penStyle = _PenStyle.marker;
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Container(color: c),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: isSelected ? AppColors.primaryContainer : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppColors.onPrimary : context.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSelected ? AppColors.onPrimary : context.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  final Rect destination;

  const _ImagePainter(this.image, this.destination);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      Paint(),
    );
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) => false;
}

class _DrawPainter extends CustomPainter {
  final List<_DrawStroke> strokes;
  final List<Offset>? activePoints;
  final Color activeColor;
  final double activeWidth;
  final _PenStyle activeStyle;

  const _DrawPainter(
    this.strokes,
    this.activePoints,
    this.activeColor,
    this.activeWidth,
    this.activeStyle,
  );

  void drawStrokes(Canvas canvas) {
    canvas.saveLayer(null, Paint());

    for (final stroke in [
      ...strokes,
      if (activePoints != null)
        _DrawStroke(activePoints!, activeColor, activeWidth, activeStyle),
    ]) {
      final paint = Paint()
        ..color = stroke.style == _PenStyle.highlighter
            ? stroke.color.withAlpha(80)
            : stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = stroke.style == _PenStyle.marker
            ? StrokeCap.round
            : StrokeCap.square
        ..style = PaintingStyle.stroke
        ..blendMode = stroke.style == _PenStyle.eraser
            ? BlendMode.clear
            : BlendMode.srcOver;

      for (var index = 1; index < stroke.points.length; index++) {
        canvas.drawLine(stroke.points[index - 1], stroke.points[index], paint);
      }
    }

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) => drawStrokes(canvas);

  @override
  bool shouldRepaint(covariant _DrawPainter oldDelegate) => true;
}
