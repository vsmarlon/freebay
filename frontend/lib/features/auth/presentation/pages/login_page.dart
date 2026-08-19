import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';
import 'package:freebay/core/components/brutalist_error_banner.dart';
import 'package:freebay/core/components/brutalist_snackbar.dart';
import 'package:freebay/core/components/brutalist_background.dart';
import 'package:freebay/core/components/brutalist_logo.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/app_typography.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/components/brutalist_biometric_modal.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/core/components/centered_form_wrapper.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    duration: const Duration(milliseconds: 700),
    vsync: this,
  )..forward();

  Animation<double> _fadeFor(double begin, double end) {
    return CurvedAnimation(
      parent: _anim,
      curve: Interval(begin, end, curve: Curves.easeOut),
    );
  }

  Animation<Offset> _slideFor(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Interval(begin, end, curve: Curves.easeOut),
      ),
    );
  }

  late final _logoFade = _fadeFor(0.0, 0.3);
  late final _logoSlide = _slideFor(0.0, 0.3);

  late final _emailFade = _fadeFor(0.14, 0.43);
  late final _emailSlide = _slideFor(0.14, 0.43);

  late final _passFade = _fadeFor(0.26, 0.57);
  late final _passSlide = _slideFor(0.26, 0.57);

  late final _rowFade = _fadeFor(0.37, 0.65);

  late final _btnFade = _fadeFor(0.49, 0.77);
  late final _btnSlide = _slideFor(0.49, 0.77);

  late final _bottomFade = _fadeFor(0.6, 0.86);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  void dispose() {
    _emailController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _anim.dispose();
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

  Future<void> _maybeOfferBiometry(UserEntity user) async {
    if (mounted && context.mounted) {
      await BrutalistBiometricModal.show(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = context.isDark;

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) async {
          if (user == null || !mounted) return;
          if (ref
              .read(authControllerProvider.notifier)
              .needsProfileCompletion(user)) {
            if (context.mounted) context.go('/complete-profile');
            return;
          }
          await _maybeOfferBiometry(user);
          if (context.mounted) context.go('/feed');
        },
        error: (err, _) {
          HapticFeedback.vibrate();
          final msg = err is String
              ? err
              : 'Credenciais inválidas ou erro de conexão. Tente novamente.';
          setState(() => _errorMessage = msg);
          BrutalistSnackBar.show(
            context,
            message: msg,
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
                    if (context.canPop())
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
                        'ENTRAR',
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CenteredFormWrapper(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacing.vMd,
                        FadeTransition(
                          opacity: _logoFade,
                          child: SlideTransition(
                            position: _logoSlide,
                            child: const BrutalistLogo(
                              fontSize: 46,
                              showBadge: true,
                              showTagline: true,
                            ),
                          ),
                        ),
                        Spacing.vXl,
                        FadeTransition(
                          opacity: _emailFade,
                          child: SlideTransition(
                            position: _emailSlide,
                            child: AppTextField(
                              controller: _emailController,
                              label: 'E-mail',
                              hint: 'seu@email.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Informe seu e-mail'
                                  : (!ValueUtils.validateEmail(v)
                                        ? 'E-mail inválido'
                                        : null),
                            ),
                          ),
                        ),
                        Spacing.vMd,
                        FadeTransition(
                          opacity: _passFade,
                          child: SlideTransition(
                            position: _passSlide,
                            child: AppTextField(
                              controller: _passwordController,
                              label: 'Senha',
                              hint: '*********',
                              obscureText: true,
                              showPasswordToggle: true,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _handleLogin(),
                              prefixIcon: Icons.lock_outline,
                              validator: (v) => (v == null || v.isEmpty)
                                  ? 'Informe sua senha'
                                  : (v.length < 8
                                        ? 'Mínimo 8 caracteres'
                                        : null),
                            ),
                          ),
                        ),
                        Spacing.vSm,
                        FadeTransition(
                          opacity: _rowFade,
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false,
                                      ),
                                      activeColor: AppColors.accentAmber,
                                      side: BorderSide(
                                        color: isDark
                                            ? AppColors.white
                                            : AppColors.onSurface,
                                        width: 2,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        'Lembrar',
                                        style: TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: context.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => context.push('/recover-password'),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      color: AppColors.accentAmber,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          Spacing.vSm,
                          BrutalistErrorBanner(
                            message: _errorMessage!,
                            onDismiss: () =>
                                setState(() => _errorMessage = null),
                          ),
                        ],
                        Spacing.vMd,
                        FadeTransition(
                          opacity: _btnFade,
                          child: SlideTransition(
                            position: _btnSlide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppButton(
                                  label: 'ENTRAR NA CONTA',
                                  size: AppButtonSize.large,
                                  isLoading: authState.isLoading,
                                  onPressed: _handleLogin,
                                ),
                                Spacing.vMd,
                                InkWell(
                                  onTap: authState.isLoading
                                      ? null
                                      : () => ref
                                            .read(
                                              authControllerProvider.notifier,
                                            )
                                            .googleLogin(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: context.borderColor.withAlpha(
                                          60,
                                        ),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.g_mobiledata,
                                          size: 22,
                                          color: context.textPrimary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'ENTRAR COM GOOGLE',
                                          style: TextStyle(
                                            fontFamily: AppTypography
                                                .headlineFontFamily,
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
                              ],
                            ),
                          ),
                        ),
                        Spacing.vLg,
                        FadeTransition(
                          opacity: _bottomFade,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'NÃO TEM UMA CONTA? ',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                              InkWell(
                                onTap: () => context.push('/register'),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    'CRIAR CONTA',
                                    style: TextStyle(
                                      fontFamily:
                                          AppTypography.headlineFontFamily,
                                      color: AppColors.accentAmber,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacing.vLg,
                      ],
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
