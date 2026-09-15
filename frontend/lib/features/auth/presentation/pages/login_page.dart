import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_stagger.dart';
import 'package:freebay/shared/services/storage_service.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    duration: AppMotion.enter,
    vsync: this,
  )..forward();

  Animation<double> _fadeFor(double begin, double end) {
    return CurvedAnimation(
      parent: _anim,
      curve: Interval(begin, end, curve: AppMotion.enterCurve),
    );
  }

  Animation<Offset> _slideFor(double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _anim,
        curve: Interval(begin, end, curve: AppMotion.enterCurve),
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
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final email = await StorageService.getEmail();
    if (!mounted ||
        email == null ||
        email.isEmpty ||
        _emailController.text.isNotEmpty) {
      return;
    }
    _emailController.text = email;
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
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
    final isDark = context.isDark;

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) async {
          if (user == null || !mounted) return;
          // ponytail: GoRouter redirect owns → /complete-profile; a second
          // context.go here races with the redirect into the error screen.
          if (ref
              .read(authControllerProvider.notifier)
              .needsProfileCompletion(user)) {
            return;
          }
          if (context.mounted) {
            final from = GoRouterState.of(context).uri.queryParameters['from'];
            context.go(resolvePostAuthDestination(from));
          }
        },
        error: (err, _) {
          HapticFeedback.vibrate();
          AppSnackbar.handleFailure(context, err);
        },
      );
    });

    return Scaffold(
      body: AppBackground(
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
                child: CenteredFormWrapper(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacing.vMd,
                        AuthStagger.fromAnimations(
                          opacity: _logoFade,
                          slide: _logoSlide,
                          child: const BrutalistLogo(
                            fontSize: 46,
                            showTagline: false,
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
                                      activeColor: AppColors.primaryContainer,
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
                                onTap: () =>
                                    context.push(AppRoutes.recoverPassword),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      fontFamily: AppTypography.fontFamily,
                                      color: AppColors.primaryContainer,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                                onTap: () => context.push(AppRoutes.register),
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
                                      color: AppColors.primaryContainer,
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
