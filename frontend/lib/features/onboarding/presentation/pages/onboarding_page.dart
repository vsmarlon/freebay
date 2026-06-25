import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.storefront_outlined,
    title: 'COMPRE E VENDA',
    body: 'Publique anúncios e encontre produtos perto de você em segundos.',
  ),
  _OnboardingSlide(
    icon: Icons.forum_outlined,
    title: 'CONVERSE DIRETO',
    body: 'Negocie com compradores e vendedores pelo chat integrado.',
  ),
  _OnboardingSlide(
    icon: Icons.shield_outlined,
    title: 'PAGAMENTO PROTEGIDO',
    body:
        'O valor fica retido até a entrega ser confirmada. Sem dor de cabeça.',
  ),
];

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
    await StorageService.setHasSeenOnboarding();
    ref.read(hasSeenOnboardingProvider.notifier).state = true;
    if (!mounted) return;
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: context.surfaceMidColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'PULAR',
                    style: AppTypography.labelLarge.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 24,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.primaryContainer
                        : AppColors.outlineVariant,
                    border: Border.all(color: context.borderColor, width: 2),
                  ),
                ),
              ),
            ),
            Spacing.vMd,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppButton(
                label: isLast ? 'COMEÇAR' : 'PRÓXIMO',
                onPressed: () {
                  if (isLast) {
                    _finish();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.linear,
                    );
                  }
                },
              ),
            ),
            Spacing.vLg,
          ],
        ),
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              border: Border.all(color: context.borderColor, width: 3),
            ),
            child: Icon(
              slide.icon,
              size: 72,
              color: AppColors.primaryContainer,
            ),
          ),
          Spacing.vXl,
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: AppTypography.h2.copyWith(color: context.textPrimary),
          ),
          Spacing.vSm,
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
