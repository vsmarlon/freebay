import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;
  int _step = 1;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final strings = l10n(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordRecovery(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _step = 2;
        } else {
          _errorMessage = strings.authRecoveryRequestFailed;
        }
      });
    }
  }

  Future<void> _resetPassword() async {
    final strings = l10n(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: _emailController.text.trim(),
          token: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go(AppRoutes.login);
      } else {
        setState(() {
          _errorMessage = strings.authRecoveryCodeInvalid;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            PageHeader(
              text: strings.authForgotPassword.toUpperCase(),
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Expanded(
              child: CenteredFormWrapper(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _emailController,
                        label: strings.authEmail,
                        hint: strings.authEmailExample,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? strings.authEmailRequired
                            : null,
                      ),
                      Spacing.vMd,
                      AnimatedSize(
                        duration: AppMotion.enter,
                        curve: AppMotion.enterCurve,
                        child: _step == 2
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  AppTextField(
                                    controller: _codeController,
                                    label: strings.authVerificationCode,
                                    hint: '123456',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.verified_outlined,
                                    validator: (v) => v == null || v.length != 6
                                        ? strings.authCodeSixDigitsRequired
                                        : null,
                                  ),
                                  Spacing.vMd,
                                  AppTextField(
                                    controller: _passwordController,
                                    label: strings.authNewPassword,
                                    hint: strings.authPasswordMinLength,
                                    obscureText: true,
                                    showPasswordToggle: true,
                                    prefixIcon: Icons.lock_outline,
                                    validator: (v) => v == null || v.length < 8
                                        ? strings.authPasswordMinLength
                                        : null,
                                  ),
                                  Spacing.vMd,
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (_errorMessage != null) ...[
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        Spacing.vMd,
                      ],
                      AppButton(
                        label: _step == 2
                            ? strings.authResetPassword
                            : strings.authSendCode,
                        isLoading: _isLoading,
                        onPressed: _step == 2 ? _resetPassword : _requestCode,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
