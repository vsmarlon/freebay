import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_header.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_stagger.dart';
import 'package:freebay/features/auth/presentation/widgets/google_auth_button.dart';
import 'package:freebay/features/auth/presentation/widgets/apple_auth_button.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

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

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final TapGestureRecognizer _registerTap = TapGestureRecognizer()
    ..onTap = () => context.push(AppRoutes.register);
  bool _rememberMe = StorageService.getRememberMeSync();

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
    _registerTap.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authControllerProvider.notifier)
          .login(
            _emailController.text.trim(),
            _passwordController.text,
            rememberMe: _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
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
              AuthHeader(
                title: strings.authLogin.toUpperCase(),
                showBack: context.canPop(),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: CenteredFormWrapper(
                  center: false,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacing.vMd,
                        AuthStagger(
                          animation: _anim,
                          begin: 0.0,
                          end: 0.3,
                          child: const FreeBayLogo(),
                        ),
                        Spacing.vXl,
                        AuthStagger(
                          animation: _anim,
                          begin: 0.14,
                          end: 0.43,
                          child: AppTextField(
                            controller: _emailController,
                            label: strings.authLoginIdentifier,
                            hint: strings.authEmailExample,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) {
                              final id = (v ?? '').trim();
                              if (id.isEmpty) return strings.authLoginRequired;
                              final isHandle =
                                  id.startsWith('@') || !id.contains('@');
                              if (isHandle) {
                                final handle =
                                    (id.startsWith('@') ? id.substring(1) : id)
                                        .toLowerCase();
                                return RegExp(
                                      r'^[a-z0-9_]{3,20}$',
                                    ).hasMatch(handle)
                                    ? null
                                    : strings.authUsernameInvalid;
                              }
                              return ValueUtils.validateEmail(id)
                                  ? null
                                  : strings.authEmailInvalid;
                            },
                          ),
                        ),
                        Spacing.vMd,
                        AuthStagger(
                          animation: _anim,
                          begin: 0.26,
                          end: 0.57,
                          child: AppTextField(
                            controller: _passwordController,
                            label: strings.authPassword,
                            hint: strings.authPasswordMask,
                            obscureText: true,
                            showPasswordToggle: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _handleLogin(),
                            prefixIcon: Icons.lock_outline,
                            validator: (v) => (v == null || v.isEmpty)
                                ? strings.authPasswordRequired
                                : (v.length < 8
                                      ? strings.authPasswordMinLength
                                      : null),
                          ),
                        ),
                        Spacing.vSm,
                        AuthStagger(
                          animation: _anim,
                          begin: 0.37,
                          end: 0.65,
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BrutalistCheckbox(
                                      value: _rememberMe,
                                      onChanged: (v) => setState(
                                        () => _rememberMe = v ?? false,
                                      ),
                                    ),
                                    Flexible(
                                      child: Text(
                                        strings.authRememberMe,
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
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 6,
                                  ),
                                  child: Text(
                                    strings.authForgotPassword,
                                    style: const TextStyle(
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
                        AuthStagger(
                          animation: _anim,
                          begin: 0.49,
                          end: 0.77,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppButton(
                                label: strings.authEnterAccount.toUpperCase(),
                                size: AppButtonSize.large,
                                isLoading: authState.isLoading,
                                onPressed: _handleLogin,
                              ),
                              Spacing.vMd,
                              GoogleAuthButton(
                                label: strings.authSignInGoogle.toUpperCase(),
                                loading: authState.isLoading,
                                onTap: () => ref
                                    .read(authControllerProvider.notifier)
                                    .googleLogin(),
                              ),
                              if (!kIsWeb &&
                                  defaultTargetPlatform ==
                                      TargetPlatform.iOS) ...[
                                Spacing.vSm,
                                AppleAuthButton(
                                  text: strings.authSignInApple,
                                  loading: authState.isLoading,
                                  onPressed: () => ref
                                      .read(authControllerProvider.notifier)
                                      .appleLogin(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Spacing.vLg,
                        AuthStagger(
                          animation: _anim,
                          begin: 0.6,
                          end: 0.86,
                          child: Text.rich(
                            TextSpan(
                              text:
                                  '${strings.authNoAccountQuestion.toUpperCase()} ',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: strings.authSignUp.toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily:
                                        AppTypography.headlineFontFamily,
                                    color: AppColors.primaryContainer,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                  recognizer: _registerTap,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
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
