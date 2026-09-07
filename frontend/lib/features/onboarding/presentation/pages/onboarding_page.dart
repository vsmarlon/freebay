import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/storage_service.dart';

class _OnboardingSlide {
  final IconData icon;
  final String stepTag;
  final String title;
  final String subtitle;
  final String body;
  final List<String> highlights;

  const _OnboardingSlide({
    required this.icon,
    required this.stepTag,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.highlights,
  });
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.storefront_outlined,
    stepTag: 'FASE 01 // SOCIAL COMMERCE',
    title: 'COMPRE E VENDA',
    subtitle: 'FEED HÍBRIDO & ANÚNCIOS',
    body:
        'Descubra produtos incríveis direto do feed social, acompanhe seus criadores favoritos e anuncie em segundos.',
    highlights: [
      '0% TAXA DE ANÚNCIO',
      'FEED PERSONALIZADO',
      'ALCANCE LOCAL & GLOBAL',
    ],
  ),
  _OnboardingSlide(
    icon: Icons.chat_bubble_outline_rounded,
    stepTag: 'FASE 02 // NEGOCIAÇÃO DIRETA',
    title: 'CONVERSA & ESCROW',
    subtitle: '100% DE PROTEÇÃO',
    body:
        'Negocie propostas em tempo real via chat direto com envio de fotos e segurança integral garantida por custódia.',
    highlights: [
      'CHAT CRIPTOGRAFADO',
      'PAGAMENTO RETIDO',
      'MEDIAÇÃO DE CONFLITOS',
    ],
  ),
  _OnboardingSlide(
    icon: Icons.account_balance_wallet_outlined,
    stepTag: 'FASE 03 // CARTEIRA & REPUTAÇÃO',
    title: 'SAQUES INSTANTÂNEOS',
    subtitle: 'SEU DINHEIRO EM CONTROLE',
    body:
        'Receba pelas suas vendas com total transparência, saque quando quiser e construa sua reputação com reviews verificadas.',
    highlights: [
      'SAQUE VIA PIX / STRIPE',
      'AVALIAÇÕES REAIS',
      'EXTRATO EM TEMPO REAL',
    ],
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
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page ?? 0);
    });
  }

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
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: BrutalistBackground(
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
                  itemCount: _slides.length,
                  onPageChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                  itemBuilder: (context, i) => _SlideView(
                    slide: _slides[i],
                    pageOffset: i - _currentPage,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 3,
                child: ClipRRect(
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _slides.length,
                    backgroundColor: Colors.white.withAlpha(30),
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

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final double pageOffset;

  const _SlideView({required this.slide, required this.pageOffset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Transform.translate(
            offset: Offset(pageOffset * -60, 0),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.brutalistGradient,
                  border: Border.all(
                    color: Colors.white.withAlpha(40),
                    width: 2,
                  ),
                ),
                child: Icon(slide.icon, size: 56, color: AppColors.white),
              ),
            ),
          ),
          Spacing.vXl,
          Transform.translate(
            offset: Offset(pageOffset * -40, 0),
            child: Column(
              children: [
                Text(
                  slide.stepTag,
                  style: AppTypography.brutalistTag.copyWith(
                    color: AppColors.primaryContainer,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacing.vXs,
                Text(
                  slide.title,
                  style: AppTypography.h1.copyWith(
                    color: context.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  slide.subtitle,
                  style: TextStyle(
                    fontFamily: AppTypography.headlineFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Spacing.vMd,
          Transform.translate(
            offset: Offset(pageOffset * -20, 0),
            child: Text(
              slide.body,
              style: AppTypography.bodyMedium.copyWith(
                color: context.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Spacing.vLg,
          Transform.translate(
            offset: Offset(pageOffset * -10, 0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: slide.highlights.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Text(
                    tag,
                    style: AppTypography.brutalistTag.copyWith(
                      color: context.textPrimary,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
