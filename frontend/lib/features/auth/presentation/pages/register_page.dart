import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/username_field.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/components/brutalist_error_banner.dart';
import 'package:freebay/core/components/brutalist_snackbar.dart';
import 'package:freebay/core/components/brutalist_background.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/components/brutalist_biometric_modal.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/core/components/centered_form_wrapper.dart';

Widget _buildAnimatedItem(
  Widget child,
  Animation<double> animation,
  Interval interval,
) {
  final curve = CurvedAnimation(parent: animation, curve: interval);
  final slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(curve);
  return FadeTransition(
    opacity: curve,
    child: SlideTransition(position: slide, child: child),
  );
}

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final errorMessage = useState<String?>(null);
    final authState = ref.watch(authControllerProvider);

    final animController = useAnimationController(
      duration: const Duration(milliseconds: 900),
    );
    useEffect(() {
      animController.forward();
      return null;
    }, const []);

    useEffect(
      () {
        void clearError() {
          if (errorMessage.value != null) {
            errorMessage.value = null;
          }
        }

        nameController.addListener(clearError);
        usernameController.addListener(clearError);
        emailController.addListener(clearError);
        passwordController.addListener(clearError);
        confirmPasswordController.addListener(clearError);

        return () {
          nameController.removeListener(clearError);
          usernameController.removeListener(clearError);
          emailController.removeListener(clearError);
          passwordController.removeListener(clearError);
          confirmPasswordController.removeListener(clearError);
        };
      },
      [
        nameController,
        usernameController,
        emailController,
        passwordController,
        confirmPasswordController,
      ],
    );

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) async {
          if (user == null || !context.mounted) return;
          if (ref
              .read(authControllerProvider.notifier)
              .needsProfileCompletion(user)) {
            context.go('/complete-profile');
            return;
          }
          await BrutalistBiometricModal.show(context, ref);
          if (context.mounted) {
            context.go('/feed');
          }
        },
        error: (err, _) {
          HapticFeedback.vibrate();
          final friendlyError = err is String
              ? err
              : 'Erro ao criar conta. Verifique os dados e tente novamente.';
          errorMessage.value = friendlyError;
          BrutalistSnackBar.show(
            context,
            message: friendlyError,
            type: BrutalistSnackBarType.error,
          );
        },
      );
    });

    return Scaffold(
      body: BrutalistBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with centered massive header (100% larger)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: context.borderColor.withAlpha(40),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: BrutalistIconButton(
                        icon: Icons.arrow_back,
                        size: 40,
                        onTap: () => context.pop(),
                      ),
                    ),
                    Center(
                      child: Text(
                        'CRIAR CONTA',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: context.textPrimary,
                          shadows: [
                            Shadow(
                              color: AppColors.accentAmber.withAlpha(80),
                              offset: const Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CenteredFormWrapper(
                    center: false,
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Spacing.vMd,
                          _buildAnimatedItem(
                            AppTextField(
                              controller: nameController,
                              label: 'Nome de exibição',
                              hint: 'Seu apelido na plataforma',
                              prefixIcon: Icons.person_outline,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe seu nome';
                                }
                                if (v.trim().length < 2) {
                                  return 'Nome muito curto';
                                }
                                return null;
                              },
                            ),
                            animController,
                            const Interval(0.0, 0.25),
                          ),
                          Spacing.vMd,
                          _buildAnimatedItem(
                            UsernameField(controller: usernameController),
                            animController,
                            const Interval(0.1, 0.33),
                          ),
                          Spacing.vMd,
                          _buildAnimatedItem(
                            AppTextField(
                              controller: emailController,
                              label: 'E-mail',
                              hint: 'seu@email.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Informe seu e-mail';
                                }
                                if (!ValueUtils.validateEmail(v)) {
                                  return 'E-mail inválido';
                                }
                                return null;
                              },
                            ),
                            animController,
                            const Interval(0.2, 0.43),
                          ),
                          Spacing.vMd,
                          _buildAnimatedItem(
                            AppTextField(
                              controller: passwordController,
                              label: 'Senha',
                              hint: 'Mínimo 8 caracteres',
                              obscureText: true,
                              showPasswordToggle: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Informe sua senha';
                                }
                                if (v.length < 8) {
                                  return 'Mínimo 8 caracteres';
                                }
                                return null;
                              },
                            ),
                            animController,
                            const Interval(0.3, 0.53),
                          ),
                          Spacing.vMd,
                          _buildAnimatedItem(
                            AppTextField(
                              controller: confirmPasswordController,
                              label: 'Confirmar Senha',
                              hint: 'Digite a senha novamente',
                              obscureText: true,
                              showPasswordToggle: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Confirme sua senha';
                                }
                                if (v != passwordController.text) {
                                  return 'As senhas não coincidem';
                                }
                                return null;
                              },
                            ),
                            animController,
                            const Interval(0.4, 0.63),
                          ),
                          if (errorMessage.value != null) ...[
                            Spacing.vSm,
                            BrutalistErrorBanner(
                              message: errorMessage.value!,
                              onDismiss: () => errorMessage.value = null,
                            ),
                          ],
                          Spacing.vLg,
                          _buildAnimatedItem(
                            AppButton(
                              label: 'FINALIZAR CADASTRO',
                              size: AppButtonSize.large,
                              isLoading: authState.isLoading,
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
                                  errorMessage.value = null;
                                  ref
                                      .read(authControllerProvider.notifier)
                                      .register(
                                        emailController.text.trim(),
                                        passwordController.text.trim(),
                                        nameController.text.trim(),
                                        usernameController.text
                                            .trim()
                                            .toLowerCase(),
                                      );
                                }
                              },
                            ),
                            animController,
                            const Interval(0.55, 0.8),
                          ),
                          Spacing.vMd,
                          _buildAnimatedItem(
                            InkWell(
                              onTap: authState.isLoading
                                  ? null
                                  : () => ref
                                        .read(authControllerProvider.notifier)
                                        .googleLogin(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: context.borderColor.withAlpha(60),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.g_mobiledata,
                                      size: 22,
                                      color: context.textPrimary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'CRIAR COM GOOGLE',
                                      style: TextStyle(
                                        fontFamily:
                                            AppTypography.headlineFontFamily,
                                        color: context.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            animController,
                            const Interval(0.65, 0.9),
                          ),
                          Spacing.vLg,
                        ],
                      ),
                    ),
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
