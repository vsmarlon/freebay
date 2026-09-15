import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../tokens/app_colors.dart';

/// Controls how [BrutalistBackground] renders.
enum BrutalistBackgroundMode {
  /// Full animated aurora shader (auth/splash screens).
  animated,

  /// One frozen aurora frame — same look, zero per-frame GPU cost.
  /// Used when the user disables background animation.
  staticAurora,

  /// Static tonal gradient — zero GPU cost, suitable for inner app screens.
  staticGradient,
}

/// Fixed timestamp (seconds) rendered by [BrutalistBackgroundMode.staticAurora].
const double kFrozenAuroraSeconds = 4.0;

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
  // Shared for the isolate lifetime; individual widgets only dispose shaders.
  static ui.Image? _noiseTexture;
  static Future<void>? _resourcesLoading;
  static bool _programFailed = false;

  ui.FragmentShader? _shader;
  Ticker? _ticker;
  ValueNotifier<double>? _seconds;
  ValueListenable<TickerModeData>? _tickerModeNotifier;
  bool _appIsResumed = true;
  bool _dependenciesReady = false;

  bool get _usesShader =>
      widget.mode == BrutalistBackgroundMode.animated ||
      widget.mode == BrutalistBackgroundMode.staticAurora;

  @override
  void initState() {
    super.initState();
    if (_usesShader) {
      _seconds = ValueNotifier(
        widget.mode == BrutalistBackgroundMode.staticAurora
            ? kFrozenAuroraSeconds
            : 0,
      );
      WidgetsBinding.instance.addObserver(this);
      _loadProgram();
    }
  }

  @override
  void didUpdateWidget(BrutalistBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode == widget.mode) return;

    if (_usesShader) {
      _seconds ??= ValueNotifier(0);
      if (widget.mode == BrutalistBackgroundMode.staticAurora) {
        _seconds!.value = kFrozenAuroraSeconds;
      }
      WidgetsBinding.instance.addObserver(this);
      _loadProgram();
    } else {
      WidgetsBinding.instance.removeObserver(this);
      _tickerModeNotifier?.removeListener(_updateTickerMute);
      _tickerModeNotifier = null;
      _ticker?.dispose();
      _ticker = null;
      _shader?.dispose();
      _shader = null;
      _seconds?.dispose();
      _seconds = null;
      setState(() {});
    }
  }

  static Future<void> _loadResources() async {
    _program = await ui.FragmentProgram.fromAsset(
      'packages/freebay_design_system/shaders/aurora.frag',
    );
    final data = await rootBundle.load(
      'packages/freebay_design_system/assets/aurora_noise.png',
    );
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      _noiseTexture = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> _loadProgram() async {
    if (_programFailed) return;
    try {
      await (_resourcesLoading ??= _loadResources());
    } catch (_) {
      _programFailed = true;
      if (mounted) setState(() {});
      return;
    }
    if (!mounted || !_usesShader) return;
    _ticker?.dispose();
    _ticker = null;
    _shader?.dispose();
    // Warp coordinates must interpolate between texels, not jump in blocks.
    _shader = _program!.fragmentShader()
      ..setImageSampler(0, _noiseTexture!, filterQuality: ui.FilterQuality.low);
    if (widget.mode == BrutalistBackgroundMode.animated) {
      _seconds!.value = 0;
      _ticker = createTicker((elapsed) {
        _seconds?.value =
            elapsed.inMicroseconds / Duration.microsecondsPerSecond;
      })..start();
      _updateTickerMute();
    } else {
      _seconds!.value = kFrozenAuroraSeconds;
    }
    setState(() {});
  }

  void _updateTickerMute() {
    if (!_dependenciesReady) {
      _ticker?.muted = !_appIsResumed;
      return;
    }
    final routeIsCurrent = ModalRoute.of(context)?.isCurrent ?? true;
    final tickerModeEnabled = _tickerModeNotifier?.value.enabled ?? true;
    _ticker?.muted = !_appIsResumed || !routeIsCurrent || !tickerModeEnabled;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_usesShader) return;
    _dependenciesReady = true;
    _tickerModeNotifier?.removeListener(_updateTickerMute);
    _tickerModeNotifier = TickerMode.getValuesNotifier(context)
      ..addListener(_updateTickerMute);
    _updateTickerMute();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_ticker == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _appIsResumed = true;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _appIsResumed = false;
    }
    _updateTickerMute();
  }

  @override
  void dispose() {
    if (_usesShader) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _tickerModeNotifier?.removeListener(_updateTickerMute);
    _ticker?.dispose();
    _shader?.dispose();
    _seconds?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.forceDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Stack(
      children: [
        Positioned.fill(
          child: RepaintBoundary(child: _buildBackground(isDark)),
        ),
        RepaintBoundary(child: widget.child),
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
        seconds: _seconds!,
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
  }) : _seconds = seconds,
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
