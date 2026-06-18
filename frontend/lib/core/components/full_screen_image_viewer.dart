import 'package:flutter/material.dart';

void showFullScreenImage(BuildContext context, String imageUrl) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => _FullScreenImageViewer(imageUrl: imageUrl),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

class _FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  State<_FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _snapBackController;
  Animation<double>? _snapBackAnimation;
  double _dragOffset = 0;

  static const double _dismissThreshold = 120;
  static const double _dismissVelocity = 700;
  static const double _dismissFadeDistance = 300;

  bool get _isZoomed => _transformationController.value != Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        setState(() => _dragOffset = _snapBackAnimation?.value ?? 0);
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _snapBackController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final velocity = details.velocity.pixelsPerSecond.dy;
    final shouldDismiss = _dragOffset.abs() > _dismissThreshold ||
        velocity.abs() > _dismissVelocity;
    if (shouldDismiss) {
      Navigator.of(context).pop();
      return;
    }
    _snapBackAnimation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _snapBackController, curve: Curves.linear),
    );
    _snapBackController.forward(from: 0);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final position = details.localPosition;
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
    } else {
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 2, -position.dy * 2, 0, 1)
        ..scaleByDouble(3.0, 3.0, 3.0, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dismissProgress =
        (_dragOffset.abs() / _dismissFadeDistance).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 1 - dismissProgress),
      body: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: _onDoubleTapDown,
            onDoubleTap: () {},
            onVerticalDragUpdate: _onVerticalDragUpdate,
            onVerticalDragEnd: _onVerticalDragEnd,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Opacity(
                opacity: 1 - dismissProgress,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
