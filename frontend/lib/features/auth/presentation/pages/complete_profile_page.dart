import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_header.dart';
import 'package:freebay/features/auth/presentation/widgets/auth_stagger.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class CompleteProfilePage extends ConsumerStatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  ConsumerState<CompleteProfilePage> createState() =>
      _CompleteProfilePageState();
}

class _CompleteProfilePageState extends ConsumerState<CompleteProfilePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    duration: AppMotion.enter,
    vsync: this,
  )..forward();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).value;
    if (user?.displayName != null) {
      _nameController.text = user!.displayName!;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _confirmCancel() async {
    final strings = l10n(context);
    await AppDialog.show(
      context: context,
      icon: Icons.logout,
      iconColor: AppColors.error,
      title: strings.authCancelRegistrationTitle,
      subtitle: strings.authCancelRegistrationBody,
      dismissText: strings.authContinueProfile,
      okText: strings.authExitToLogin,
      isError: true,
      onOk: () async {
        await ref.read(authControllerProvider.notifier).logout();
        if (mounted && context.mounted) {
          context.go(AppRoutes.login);
        }
      },
    );
  }

  Future<void> _handleComplete() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await ref
        .read(authControllerProvider.notifier)
        .completeProfile(
          username: _usernameController.text.trim().toLowerCase(),
          displayName: _nameController.text.trim(),
          city: _cityController.text.trim().isEmpty
              ? null
              : _cityController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (user) async {
          if (user != null && user.username != null && mounted) {
            if (mounted && context.mounted) context.go(AppRoutes.feed);
          }
        },
        error: (err, _) {
          HapticFeedback.vibrate();
          AppSnackbar.handleFailure(context, err);
        },
      );
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmCancel();
        }
      },
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                AuthHeader(
                  title: strings.authCompleteProfileTitle.toUpperCase(),
                  onBack: _confirmCancel,
                  backTooltip: strings.authBackToLogin,
                ),
                Expanded(
                  child: CenteredFormWrapper(
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                strings.authCompleteProfileBody,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 14,
                                  color: context.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          Spacing.vLg,
                          AuthStagger(
                            animation: _anim,
                            begin: 0.14,
                            end: 0.43,
                            child: AppTextField(
                              controller: _nameController,
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
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            animation: _anim,
                            begin: 0.26,
                            end: 0.57,
                            child: UsernameField(
                              controller: _usernameController,
                              label: strings.authUsernameLabel,
                            ),
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            animation: _anim,
                            begin: 0.37,
                            end: 0.65,
                            child: AppTextField(
                              controller: _cityController,
                              label: strings.authCityOptional,
                              hint: strings.authCityHint,
                              prefixIcon: Icons.location_city_outlined,
                            ),
                          ),
                          Spacing.vLg,
                          AuthStagger(
                            animation: _anim,
                            begin: 0.49,
                            end: 0.77,
                            child: AppButton(
                              label: strings.commonFinish.toUpperCase(),
                              size: AppButtonSize.large,
                              isLoading: authState.isLoading,
                              onPressed: _handleComplete,
                            ),
                          ),
                          Spacing.vMd,
                          Center(
                            child: TextButton.icon(
                              onPressed: _confirmCancel,
                              icon: Icon(
                                Icons.logout,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              label: Text(
                                strings.authSwitchAccount,
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
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
      ),
    );
  }
}
