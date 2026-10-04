import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String token;
  final String email;
  const ResetPasswordPage({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = l10n(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await ref
        .read(authControllerProvider.notifier)
        .resetPassword(
          email: widget.email,
          token: widget.token,
          newPassword: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go(AppRoutes.login);
      } else {
        setState(() {
          _errorMessage = strings.authResetPasswordFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.authResetPassword.toUpperCase(),
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
                      Text(
                        strings.authCreateNewPassword,
                        style: TextStyle(
                          fontFamily: AppTypography.headlineFontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary,
                        ),
                      ),
                      Spacing.vSm,
                      Text(
                        strings.authStrongPasswordHint,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                      Spacing.vXl,
                      AppTextField(
                        controller: _passwordController,
                        label: strings.authNewPassword,
                        hint: strings.authPasswordMinLength,
                        obscureText: true,
                        showPasswordToggle: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return strings.authNewPasswordRequired;
                          }
                          if (v.length < 8) {
                            return strings.authPasswordMinLength;
                          }
                          return null;
                        },
                      ),
                      Spacing.vMd,
                      AppTextField(
                        controller: _confirmController,
                        label: strings.authConfirmNewPassword,
                        hint: strings.authRepeatNewPassword,
                        obscureText: true,
                        showPasswordToggle: true,
                        prefixIcon: Icons.lock_outline,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return strings.authConfirmNewPasswordRequired;
                          }
                          if (v != _passwordController.text) {
                            return strings.authPasswordMismatch;
                          }
                          return null;
                        },
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
                      Spacing.vLg,
                      AppButton(
                        label: strings.authResetPassword,
                        isLoading: _isLoading,
                        onPressed: _submit,
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
