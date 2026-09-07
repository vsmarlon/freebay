import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/services/storage_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: AppMotion.enter,
  )..forward();

  late final Animation<double> _logoOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.0, 0.25, curve: AppMotion.enterCurve),
        ),
      );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.9, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.0, 0.25, curve: AppMotion.enterCurve),
        ),
      );

  late final Animation<double> _taglineOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.166, 0.375, curve: AppMotion.enterCurve),
        ),
      );
  late final Animation<Offset> _taglineSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.166, 0.375, curve: AppMotion.enterCurve),
        ),
      );

  late final Animation<double> _statsOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.416, 0.625, curve: AppMotion.enterCurve),
        ),
      );
  late final Animation<Offset> _statsSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.416, 0.625, curve: AppMotion.enterCurve),
        ),
      );

  late final Animation<double> _btnOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.666, 0.916, curve: AppMotion.enterCurve),
        ),
      );
  late final Animation<Offset> _btnSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.666, 0.916, curve: AppMotion.enterCurve),
        ),
      );

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowestDark,
      body: BrutalistBackground(
        forceDark: true,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: const Text(
                          'THE MARKETPLACE REBUILT',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: AppColors.onSurfaceVariantDark,
                          ),
                        ),
                      ),
                      Spacing.vMd,
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const Text(
                            'freebay',
                            style: TextStyle(
                              fontFamily: AppTypography.headlineFontFamily,
                              fontSize: 80,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Spacing.vSm,
                      SlideTransition(
                        position: _taglineSlide,
                        child: FadeTransition(
                          opacity: _taglineOpacity,
                          child: const Text(
                            'TRADE YOUR WORLD',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: AppColors.primaryContainer,
                            ),
                          ),
                        ),
                      ),
                      Spacing.vXxl,
                      SlideTransition(
                        position: _btnSlide,
                        child: FadeTransition(
                          opacity: _btnOpacity,
                          child: _GetStartedButton(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final hasSeen =
                                  StorageService.hasSeenOnboardingSync();
                              context.go(hasSeen ? '/login' : '/onboarding');
                            },
                          ),
                        ),
                      ),
                      Spacing.vXxl,
                      SlideTransition(
                        position: _statsSlide,
                        child: FadeTransition(
                          opacity: _statsOpacity,
                          child: const Row(
                            children: [
                              Expanded(
                                child: _StatBlock(
                                  value: '0%',
                                  label: 'Trading Fees',
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _StatBlock(
                                  value: 'Instant',
                                  label: 'Verification',
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _StatBlock(
                                  value: 'Global',
                                  label: 'Reach Access',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppMotion.tap,
        transform: Matrix4.translationValues(
          _isPressed ? AppDepth.pressOffset : 0.0,
          _isPressed ? AppDepth.pressOffset : 0.0,
          0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: _isPressed
              ? []
              : AppDepth.hard(AppColors.primaryContainer),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'GET STARTED',
              style: TextStyle(
                fontFamily: AppTypography.headlineFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.black,
              ),
            ),
            Icon(Icons.arrow_forward, size: 22, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;

  const _StatBlock({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.headlineFontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
        Spacing.vXs,
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: AppColors.onSurfaceVariantDark,
          ),
        ),
      ],
    );
  }
}
