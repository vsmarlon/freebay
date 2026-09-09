import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../tokens/app_colors.dart';

/// Controls how [BrutalistBackground] renders.
enum BrutalistBackgroundMode {
  /// Full animated aurora shader (auth/splash screens).
  animated,

  /// Static tonal gradient — zero GPU cost, suitable for inner app screens.
  staticGradient,
}

class BrutalistBackground extends StatefulWidget {
  final Widget child;
  final bool? forceDark;
  final BrutalistBackgroundMode mode;

  const BrutalistBackground({
    required this.child,
    this.forceDark,
    this.mode = BrutalistBackgroundMode.animated,
    super.key,
  });

  @override
  State<BrutalistBackground> createState() => _BrutalistBackgroundState();
}

class _BrutalistBackgroundState extends State<BrutalistBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static ui.FragmentProgram? _program;
  static bool _programFailed = false;

  ui.FragmentShader? _shader;
  Ticker? _ticker;
  final ValueNotifier<double> _seconds = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.mode == BrutalistBackgroundMode.animated) {
      _loadProgram();
    }
  }

  Future<void> _loadProgram() async {
    if (_programFailed) return;
    if (_program == null) {
      try {
        _program = await ui.FragmentProgram.fromAsset(
          'packages/freebay_design_system/shaders/aurora.frag',
        );
      } catch (_) {
        _programFailed = true;
        if (mounted) setState(() {});
        return;
      }
    }
    if (!mounted) return;
    _shader = _program!.fragmentShader();
    _ticker = createTicker((elapsed) {
      _seconds.value = elapsed.inMilliseconds / 1000.0;
    })..start();
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ticker == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _ticker!.muted = false;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _ticker!.muted = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.dispose();
    _shader?.dispose();
    _seconds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.forceDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: _buildBackground(isDark),
          ),
        ),
        widget.child,
      ],
    );
  }

  Widget _buildBackground(bool isDark) {
    // Static mode or shader not yet loaded — zero GPU cost
    if (widget.mode == BrutalistBackgroundMode.staticGradient ||
        _shader == null) {
      return _StaticBackground(isDark: isDark);
    }

    return CustomPaint(
      size: Size.infinite,
      painter: _AuroraShaderPainter(
        shader: _shader!,
        seconds: _seconds,
        isDark: isDark,
      ),
    );
  }
}

class _StaticBackground extends StatelessWidget {
  const _StaticBackground({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  AppColors.surfaceContainerLowestDark,
                  AppColors.surfaceDark,
                  AppColors.surfaceContainerLowDark,
                ]
              : const [
                  AppColors.surfaceContainerLowest,
                  AppColors.surface,
                  AppColors.surfaceContainerLow,
                ],
        ),
      ),
    );
  }
}

class _AuroraShaderPainter extends CustomPainter {
  _AuroraShaderPainter({
    required this.shader,
    required ValueNotifier<double> seconds,
    required this.isDark,
  })  : _seconds = seconds,
        super(repaint: seconds);

  final ui.FragmentShader shader;
  final ValueNotifier<double> _seconds;
  final bool isDark;

  static final Paint _shaderPaint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, _seconds.value)
      ..setFloat(3, isDark ? 1.0 : 0.0);
    _shaderPaint.shader = shader;
    canvas.drawRect(Offset.zero & size, _shaderPaint);
  }

  @override
  bool shouldRepaint(covariant _AuroraShaderPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
