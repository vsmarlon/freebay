import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/components/brutalist_background.dart';
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
    duration: const Duration(milliseconds: 1200),
  )..forward();

  late final Animation<double> _logoOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
        ),
      );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.9, end: 1.0)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
        ),
      );

  late final Animation<double> _taglineOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.166, 0.375, curve: Curves.easeOut),
        ),
      );
  late final Animation<Offset> _taglineSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.166, 0.375, curve: Curves.easeOut),
        ),
      );

  late final Animation<double> _statsOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.416, 0.625, curve: Curves.easeOut),
        ),
      );
  late final Animation<Offset> _statsSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.416, 0.625, curve: Curves.easeOut),
        ),
      );

  late final Animation<double> _btnOpacity = Tween<double>(begin: 0, end: 1)
      .animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.666, 0.916, curve: Curves.easeOut),
        ),
      );
  late final Animation<Offset> _btnSlide =
      Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _anim,
          curve: const Interval(0.666, 0.916, curve: Curves.easeOut),
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
      backgroundColor: const Color(0xFF07000C),
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
                        child: Text(
                          'THE MARKETPLACE REBUILT',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2.0,
                            color: const Color(0xFFB0B0B0),
                          ),
                        ),
                      ),
                      Spacing.vMd,
                      FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Text(
                            'freebay',
                            style: TextStyle(
                              fontFamily: AppTypography.headlineFontFamily,
                              fontSize: 80,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -3,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: AppColors.primary.withAlpha(160),
                                  offset: const Offset(0, 4),
                                  blurRadius: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Spacing.vSm,
                      SlideTransition(
                        position: _taglineSlide,
                        child: FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            'TRADE YOUR WORLD',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.5,
                              color: AppColors.accentAmber,
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
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? 3 : 0,
          _isPressed ? 3 : 0,
          0,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: _isPressed
              ? []
              : const [
                  BoxShadow(
                    color: Color(0xFF8A1083),
                    offset: Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
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
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            color: const Color(0xFFA0A0A0),
          ),
        ),
      ],
    );
  }
}
