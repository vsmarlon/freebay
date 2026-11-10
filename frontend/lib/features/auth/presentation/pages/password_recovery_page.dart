import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_header.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PasswordRecoveryPage extends ConsumerStatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  ConsumerState<PasswordRecoveryPage> createState() =>
      _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends ConsumerState<PasswordRecoveryPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    final strings = l10n(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final success = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordRecovery(email);

    if (!mounted) return;
    setState(() => _isLoading = false);
    if (success) {
      context.push(
        '${AppRoutes.verifyResetCode}?email=${Uri.encodeComponent(email)}',
      );
    } else {
      setState(() => _errorMessage = strings.authRecoveryRequestFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              AuthHeader(
                title: strings.authForgotPassword.toUpperCase(),
                onBack: () => context.pop(),
              ),
              Expanded(
                child: CenteredFormWrapper(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Spacing.vLg,
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/recovery_lock.svg',
                            width: 200,
                          ),
                        ),
                        Spacing.vMd,
                        Text(
                          strings.authRecoveryHint,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                        Spacing.vLg,
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
                        if (_errorMessage != null) ...[
                          Spacing.vMd,
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                        Spacing.vLg,
                        AppButton(
                          label: strings.authSendCode,
                          isLoading: _isLoading,
                          onPressed: _requestCode,
                        ),
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
