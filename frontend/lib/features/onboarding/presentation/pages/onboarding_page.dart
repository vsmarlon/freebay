import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/onboarding/presentation/pages/onboarding_slides.dart';
import 'package:freebay/shared/services/storage_service.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await StorageService.setHasSeenOnboarding();
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    routerRefreshNotifier.value++;
    if (!mounted) return;
    final user = ref.read(authControllerProvider).value;
    if (context.mounted) context.go(user != null ? '/feed' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == onboardingSlides.length - 1;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      'assets/freebay-textonly.png',
                      height: 28,
                      fit: BoxFit.contain,
                      color: context.isDark
                          ? AppColors.white
                          : AppColors.primaryContainer,
                    ),
                    GestureDetector(
                      onTap: _finish,
                      child: const Text(
                        'PULAR',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: onboardingSlides.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (context, i) => AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) => OnboardingSlideView(
                      slide: onboardingSlides[i],
                      pageOffset:
                          i -
                          (_pageController.hasClients
                              ? (_pageController.page ?? _index.toDouble())
                              : _index.toDouble()),
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 3,
                child: ClipRRect(
                  child: LinearProgressIndicator(
                    value: (_index + 1) / onboardingSlides.length,
                    backgroundColor: context.borderSoftColor,
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryContainer,
                    ),
                  ),
                ),
              ),
              Spacing.vSm,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: AppButton(
                  label: isLast ? 'COMEÇAR AGORA' : 'PRÓXIMO',
                  icon: isLast
                      ? Icons.rocket_launch_outlined
                      : Icons.arrow_forward,
                  size: AppButtonSize.large,
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _pageController.nextPage(
                        duration: AppMotion.enter,
                        curve: AppMotion.baseCurve,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
