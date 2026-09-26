import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/pages/splash_widgets.dart';
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
      body: AppBackground(
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
                          child: SplashGetStartedButton(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              final hasSeen =
                                  StorageService.hasSeenOnboardingSync();
                              context.go(
                                hasSeen
                                    ? AppRoutes.login
                                    : AppRoutes.onboarding,
                              );
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
                                child: SplashStatBlock(
                                  value: '0%',
                                  label: 'Trading Fees',
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: SplashStatBlock(
                                  value: 'Instant',
                                  label: 'Verification',
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: SplashStatBlock(
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
