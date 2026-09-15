import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/services/notification_service.dart';
import 'package:freebay/shared/services/storage_service.dart';

/// Post-login setup shown once per account. Step 1 is biometry opt-in,
/// followed by notification opt-in and a finish step.
class WelcomeSetupPage extends ConsumerStatefulWidget {
  const WelcomeSetupPage({super.key});

  @override
  ConsumerState<WelcomeSetupPage> createState() => _WelcomeSetupPageState();
}

class _WelcomeSetupPageState extends ConsumerState<WelcomeSetupPage> {
  int _step = 0;
  bool _busy = false;

  Future<void> _finish() async {
    // Riverpod 3: .value is null (never throws) while loading/in error.
    var user = ref.read(authControllerProvider).value;
    // Auth may still be hydrating; wait briefly instead of losing the flag
    // (without it, /feed would bounce straight back to /welcome).
    for (var i = 0; user == null && i < 20 && mounted; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      user = ref.read(authControllerProvider).value;
    }
    if (user != null) {
      await StorageService.setWelcomeSetupDone(user.id);
    }
    if (!mounted) return;
    // go() alone re-evaluates the router redirect; no manual bump needed.
    context.go(AppRoutes.feed);
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _enableBiometry() async {
    setState(() => _busy = true);
    try {
      final biometryService = ref.read(biometryServiceProvider);
      final authenticated = await biometryService.authenticate(
        reason: 'Confirme para ativar login biométrico',
      );
      if (!authenticated) return;

      final enrollment = await ref
          .read(authRepositoryProvider)
          .enrollBiometricToken();
      if (enrollment.isLeft) {
        if (mounted) {
          AppSnackbar.error(context, 'Não foi possível ativar a biometria.');
        }
        return;
      }
      final token = enrollment.rightOrNull;
      if (token == null || token.isEmpty) {
        if (mounted) {
          AppSnackbar.error(context, 'Não foi possível ativar a biometria.');
        }
        return;
      }
      final user = ref.read(authControllerProvider).value;
      if (user == null) return;
      await StorageService.saveBiometricToken(token);
      await StorageService.saveBiometricOwner(user.id);
      await biometryService.setEnabled(true);
      await biometryService.setHasPrompted(true);
      await StorageService.saveRememberMe(true);
      ref.invalidate(biometryEnabledProvider);
      _next();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enableNotifications() async {
    setState(() => _busy = true);
    try {
      await NotificationService().requestPermissions();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = ref.watch(biometryAvailableProvider).value ?? false;
    final isEnabled = ref.watch(biometryEnabledProvider).value ?? false;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'PASSO ${_step + 1} DE 3',
                  style: AppTypography.brutalistTag.copyWith(
                    color: AppColors.primaryContainer,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                Spacing.vMd,
                LinearProgressIndicator(
                  value: (_step + 1) / 3,
                  backgroundColor: context.borderColor.withAlpha(60),
                  valueColor: const AlwaysStoppedAnimation(
                    AppColors.primaryContainer,
                  ),
                ),
                Spacing.vXl,
                Expanded(child: _buildStep(isAvailable, isEnabled)),
                Spacing.vLg,
                if (_step == 0 && isAvailable && !isEnabled)
                  AppButton(
                    label: 'Ativar biometria',
                    icon: Icons.fingerprint,
                    isLoading: _busy,
                    onPressed: _enableBiometry,
                  )
                else if (_step == 1)
                  AppButton(
                    label: 'Ativar notificações',
                    icon: Icons.notifications_outlined,
                    isLoading: _busy,
                    onPressed: _enableNotifications,
                  )
                else
                  AppButton(
                    label: _step == 2 ? 'Concluir' : 'Continuar',
                    icon: Icons.arrow_forward,
                    onPressed: _busy ? null : _next,
                  ),
                Spacing.vSm,
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _step == 2 ? 'Voltar ao início' : 'Agora não',
                    variant: AppButtonVariant.ghost,
                    onPressed: _busy
                        ? null
                        : () {
                            if (_step == 2) {
                              _finish();
                            } else {
                              _next();
                            }
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(bool isAvailable, bool isEnabled) {
    switch (_step) {
      case 0:
        return _StepContent(
          icon: Icons.fingerprint,
          title: 'ENTRE COM BIOMETRIA',
          body: isAvailable
              ? 'Use sua impressão digital ou Face ID para entrar rapidamente, sem digitar sua senha.'
              : 'Seu dispositivo não suporta biometria. Você pode continuar sem ela.',
          status: !isAvailable
              ? 'Não disponível neste dispositivo'
              : isEnabled
              ? 'Biometria já ativada'
              : null,
        );
      case 1:
        return const _StepContent(
          icon: Icons.notifications_outlined,
          title: 'FIQUE POR DENTRO',
          body:
              'Receba avisos de vendas, mensagens no chat e atualizações dos seus pedidos em tempo real.',
        );
      default:
        return const _StepContent(
          icon: Icons.rocket_launch_outlined,
          title: 'TUDO PRONTO',
          body:
              'Sua conta está configurada. Você pode mudar biometria e fundo animado quando quiser em Perfil > Configurações.',
        );
    }
  }
}

class _StepContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? status;

  const _StepContent({
    required this.icon,
    required this.title,
    required this.body,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.brutalistGradient,
              border: Border.all(
                color: context.borderColor.withAlpha(60),
                width: 2,
              ),
            ),
            child: Icon(icon, size: 56, color: AppColors.white),
          ),
        ),
        Spacing.vXl,
        Text(
          title,
          style: AppTypography.h1.copyWith(
            color: context.textPrimary,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        Spacing.vMd,
        Text(
          body,
          style: AppTypography.bodyMedium.copyWith(
            color: context.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (status != null) ...[
          Spacing.vMd,
          Text(
            status!,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              color: AppColors.primaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
