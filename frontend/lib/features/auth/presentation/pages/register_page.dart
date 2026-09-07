// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_stagger.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final errorMessage = useState<String?>(null);
    final authState = ref.watch(authControllerProvider);

    final animController = useAnimationController(duration: AppMotion.enter);
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
          AppSnackbar.error(context, friendlyError);
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
                            const Shadow(
                              color: AppColors.primaryContainer,
                              offset: AppDepth.shadowOffsetSmall,
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
                          AuthStagger(
                            child: AppTextField(
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
                            animation: animController,
                            begin: 0.0,
                            end: 0.25,
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            child: UsernameField(
                              controller: usernameController,
                            ),
                            animation: animController,
                            begin: 0.1,
                            end: 0.33,
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            child: AppTextField(
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
                            animation: animController,
                            begin: 0.2,
                            end: 0.43,
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            child: AppTextField(
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
                            animation: animController,
                            begin: 0.3,
                            end: 0.53,
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            child: AppTextField(
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
                            animation: animController,
                            begin: 0.4,
                            end: 0.63,
                          ),
                          if (errorMessage.value != null) ...[
                            Spacing.vSm,
                            EmptyState.error(
                              message: errorMessage.value!,
                              onRetry: () => errorMessage.value = null,
                            ),
                          ],
                          Spacing.vLg,
                          AuthStagger(
                            child: AppButton(
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
                            animation: animController,
                            begin: 0.55,
                            end: 0.8,
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            child: InkWell(
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
                            animation: animController,
                            begin: 0.65,
                            end: 0.9,
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
