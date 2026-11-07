// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class RegisterPage extends HookConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = l10n(context);
    final nameController = useTextEditingController();
    final usernameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final authState = ref.watch(authControllerProvider);

    final animController = useAnimationController(duration: AppMotion.enter);
    useEffect(() {
      animController.forward();
      return null;
    }, const []);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) async {
          if (user == null || !context.mounted) return;
          // ponytail: GoRouter redirect owns → /complete-profile; a second
          // context.go here races with the redirect into the error screen.
          if (ref
              .read(authControllerProvider.notifier)
              .needsProfileCompletion(user)) {
            return;
          }
          if (context.mounted) {
            context.go(AppRoutes.feed);
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
              // Top Bar with centered massive header (100% larger)
              AuthHeader(
                title: strings.authSignUp.toUpperCase(),
                onBack: () => context.pop(),
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
                              label: strings.authDisplayName,
                              hint: strings.authDisplayNameHint,
                              prefixIcon: Icons.person_outline,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return strings.authNameRequired;
                                }
                                if (v.trim().length < 2) {
                                  return strings.authNameTooShort;
                                }
                                if (!ValueUtils.validateDisplayName(v)) {
                                  return strings.authNameInvalid;
                                }
                                return null;
                              },
                            ),
                            animation: animController,
                            begin: 0.0,
                            end: 0.25,
                          ),
                          if (!kIsWeb &&
                              defaultTargetPlatform == TargetPlatform.iOS) ...[
                            Spacing.vSm,
                            AuthStagger(
                              child: AppleAuthButton(
                                text: strings.authSignUpApple,
                                loading: authState.isLoading,
                                onPressed: () => ref
                                    .read(authControllerProvider.notifier)
                                    .appleLogin(),
                              ),
                              animation: animController,
                              begin: 0.72,
                              end: 0.95,
                            ),
                          ],
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
                              label: strings.authEmail,
                              hint: strings.authEmailExample,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return strings.authEmailRequired;
                                }
                                if (!ValueUtils.validateEmail(v)) {
                                  return strings.authEmailInvalid;
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
                              label: strings.authPassword,
                              hint: strings.authPasswordMinLength,
                              obscureText: true,
                              showPasswordToggle: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return strings.authPasswordRequired;
                                }
                                if (v.length < 8) {
                                  return strings.authPasswordMinLength;
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
                              label: strings.authConfirmPassword,
                              hint: strings.authRepeatPassword,
                              obscureText: true,
                              showPasswordToggle: true,
                              prefixIcon: Icons.lock_outline,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return strings.authConfirmPasswordRequired;
                                }
                                if (v != passwordController.text) {
                                  return strings.authPasswordMismatch;
                                }
                                return null;
                              },
                            ),
                            animation: animController,
                            begin: 0.4,
                            end: 0.63,
                          ),
                          Spacing.vLg,
                          AuthStagger(
                            child: AppButton(
                              label: strings.authFinishRegistration
                                  .toUpperCase(),
                              size: AppButtonSize.large,
                              isLoading: authState.isLoading,
                              onPressed: () {
                                if (formKey.currentState?.validate() ?? false) {
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
                            child: GoogleAuthButton(
                              label: strings.authSignUpGoogle.toUpperCase(),
                              loading: authState.isLoading,
                              onTap: () => ref
                                  .read(authControllerProvider.notifier)
                                  .googleLogin(),
                            ),
                            animation: animController,
                            begin: 0.65,
                            end: 0.9,
                          ),
                          if (!kIsWeb &&
                              defaultTargetPlatform == TargetPlatform.iOS) ...[
                            Spacing.vSm,
                            AuthStagger(
                              child: AppleAuthButton(
                                text: strings.authSignUpApple,
                                loading: authState.isLoading,
                                onPressed: () => ref
                                    .read(authControllerProvider.notifier)
                                    .appleLogin(),
                              ),
                              animation: animController,
                              begin: 0.72,
                              end: 0.95,
                            ),
                          ],
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
