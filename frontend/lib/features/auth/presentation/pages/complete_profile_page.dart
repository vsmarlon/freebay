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
    await AppDialog.show(
      context: context,
      icon: Icons.logout,
      iconColor: AppColors.error,
      title: 'Cancelar cadastro?',
      subtitle:
          'Se você sair agora, seu perfil não será concluído e você voltará para a tela de login.',
      dismissText: 'Continuar perfil',
      okText: 'Sair para o login',
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
                  title: 'COMPLETAR PERFIL',
                  onBack: _confirmCancel,
                  backTooltip: 'Voltar ao login',
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
                                'Escolha seu @username e preencha seus dados.',
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
                                if (!ValueUtils.validateDisplayName(v)) {
                                  return 'Nome contém caracteres inválidos';
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
                            child: AppTextField(
                              controller: _usernameController,
                              label: '@ Username',
                              hint: 'seu_username',
                              prefixIcon: Icons.alternate_email,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Escolha um username';
                                }
                                if (v.trim().length < 3) {
                                  return 'Mínimo 3 caracteres';
                                }
                                if (v.trim().length > 20) {
                                  return 'Máximo 20 caracteres';
                                }
                                if (!ValueUtils.validateUsername(v.trim())) {
                                  return 'Apenas letras minúsculas, números e _';
                                }
                                return null;
                              },
                            ),
                          ),
                          Spacing.vMd,
                          AuthStagger(
                            animation: _anim,
                            begin: 0.37,
                            end: 0.65,
                            child: AppTextField(
                              controller: _cityController,
                              label: 'Cidade (opcional)',
                              hint: 'Sua cidade',
                              prefixIcon: Icons.location_city_outlined,
                            ),
                          ),
                          Spacing.vLg,
                          AuthStagger(
                            animation: _anim,
                            begin: 0.49,
                            end: 0.77,
                            child: AppButton(
                              label: 'FINALIZAR',
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
                                'Sair e escolher outra conta',
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
