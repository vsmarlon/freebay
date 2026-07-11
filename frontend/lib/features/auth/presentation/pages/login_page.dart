import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/shared/services/biometry_service.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/core/components/centered_form_wrapper.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.linear),
        );
    _animationController.forward();

    Future.microtask(() async {
      final biometry = BiometryService();
      if (await biometry.isEnabled()) {
        final authenticated = await biometry.authenticate(
          reason: 'Autentique para acessar sua conta',
        );
        if (authenticated && mounted) {
          await ref.read(authControllerProvider.notifier).tryRefreshSession();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _errorMessage = null);
      await ref
          .read(authControllerProvider.notifier)
          .login(
            _emailController.text.trim(),
            _passwordController.text.trim(),
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) {
          if (user != null) context.go('/feed');
        },
        error: (err, _) {
          setState(
            () => _errorMessage = err is String
                ? err
                : 'Erro ao fazer login. Tente novamente.',
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'ENTRAR',
            // Only show a back button when there's somewhere to return to
            // (e.g. a guest tapped "Entrar"). After logout the stack is reset
            // (context.go('/login')) so canPop() is false and no arrow shows.(fool proof ## TODO SON)
            leading: context.canPop()
                ? BrutalistIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.pop(),
                  )
                : null,
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: CenteredFormWrapper(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Image.asset(
                          'assets/freebay-textonly.png',
                          height: 56,
                          fit: BoxFit.contain,
                          color: context.isDark
                              ? AppColors.white
                              : AppColors.primaryContainer,
                        ),
                        Spacing.vXl,
                        AppTextField(
                          controller: _emailController,
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
                        Spacing.vMd,
                        AppTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          hint: '*********',
                          obscureText: true,
                          showPasswordToggle: true,
                          prefixIcon: Icons.lock_outline,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe sua senha';
                            }
                            if (v.length < 8) return 'Mínimo 8 caracteres';
                            return null;
                          },
                        ),
                        Spacing.vSm,
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              activeColor: AppColors.primaryContainer,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              side: BorderSide(
                                color: context.isDark
                                    ? AppColors.white
                                    : AppColors.onSurface,
                                width: 2,
                              ),
                            ),
                            Text(
                              'Manter logado',
                              style: TextStyle(color: context.textPrimary),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () => context.push('/recover-password'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              child: Text(
                                'Esqueceu a senha?',
                                style: TextStyle(
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        Spacing.vMd,
                        AppButton(
                          label: 'Entrar',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: authState.isLoading
                              ? null
                              : () async {
                                  setState(() => _errorMessage = null);
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .loginAsGuest();
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Entrar como convidado',
                              style: TextStyle(
                                color: AppColors.mediumGray,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Spacing.vSm,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Não tem conta? ',
                              style: TextStyle(color: context.textPrimary),
                            ),
                            InkWell(
                              onTap: () => context.push('/register'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  'Criar conta',
                                  style: TextStyle(
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
