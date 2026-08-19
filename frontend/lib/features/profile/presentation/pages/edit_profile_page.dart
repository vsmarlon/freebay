import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/components/page_header.dart';
import 'package:freebay/core/components/shimmer_skeleton.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/username_field.dart';
import 'package:freebay/core/components/brutalist_icon_button.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cpfController = TextEditingController();
  bool _isLoading = false;
  String _originalMaskedCpf = '';
  String _originalUsername = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _cpfController.addListener(_onCpfChanged);
  }

  void _onCpfChanged() {
    final text = _cpfController.text;
    if (text.contains('*')) return; // Don't format the masked CPF
    final digits = text.replaceAll(RegExp(r'\D'), '');

    String formatted = text;
    if (digits.isEmpty) {
      formatted = '';
    } else if (digits.length == 11) {
      formatted = ValueUtils.formatCPF(digits);
    } else if (digits.length == 14) {
      formatted = ValueUtils.formatCNPJ(digits);
    }

    if (formatted != text) {
      _cpfController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _loadProfileData() {
    final profileAsync = ref.read(profileFutureProvider('me'));
    profileAsync.whenData((user) {
      _displayNameController.text = user.displayName ?? '';
      _originalUsername = (user.username ?? '').toLowerCase();
      _usernameController.text = _originalUsername;
      _bioController.text = user.bio ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
      _originalMaskedCpf = user.cpf ?? '';
      _cpfController.text = _originalMaskedCpf;
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(profileRepositoryProvider);
      final cpfText = _cpfController.text.trim();
      final isPristine = cpfText == _originalMaskedCpf;
      final cpfDigits = isPristine
          ? null
          : cpfText.replaceAll(RegExp(r'\D'), '');

      final usernameText = _usernameController.text.trim().toLowerCase();
      final result = await repository.updateProfile(
        displayName: _displayNameController.text.trim(),
        username: usernameText == _originalUsername ? null : usernameText,
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        cpf: cpfDigits?.isEmpty == true ? null : cpfDigits,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        },
        (updatedUser) {
          ref.read(authControllerProvider.notifier).setUser(updatedUser);
          ref.invalidate(profileFutureProvider('me'));
          context.pop();
        },
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final profileAsync = ref.watch(profileFutureProvider('me'));

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Column(
        children: [
          PageHeader(
            text: 'EDITAR PERFIL',
            leading: BrutalistIconButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
            actions: [
              InkWell(
                onTap: _isLoading ? null : _saveProfile,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: _isLoading
                      ? const ShimmerBlock(width: 80, height: 80)
                      : const Text(
                          'Salvar',
                          style: TextStyle(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
            breadcrumbs: context.breadcrumbs,
          ),
          Expanded(
            child: profileAsync.when(
              data: (_) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Spacing.vMd,
                      AppTextField(
                        controller: _displayNameController,
                        label: 'Nome',
                        hint: 'Seu nome',
                        maxLength: 50,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nome é obrigatório';
                          }
                          if (value.trim().length < 2) {
                            return 'Nome deve ter pelo menos 2 caracteres';
                          }
                          return null;
                        },
                      ),
                      Spacing.vLg,
                      UsernameField(
                        controller: _usernameController,
                        initialUsername: _originalUsername,
                      ),
                      Spacing.vLg,
                      AppTextField(
                        controller: _bioController,
                        label: 'Bio',
                        hint: 'Conte um pouco sobre você',
                        maxLines: 3,
                        maxLength: 150,
                      ),
                      Spacing.vLg,
                      AppTextField(
                        controller: _cityController,
                        label: 'Cidade',
                        hint: 'Sua cidade',
                      ),
                      Spacing.vLg,
                      AppTextField(
                        controller: _stateController,
                        label: 'Estado',
                        hint: 'Seu estado',
                      ),
                      Spacing.vLg,
                      AppTextField(
                        controller: _cpfController,
                        label: 'CPF / CNPJ',
                        hint:
                            'Digite seu CPF (11 dígitos) ou CNPJ (14 dígitos)',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d\-./*]'),
                          ),
                          LengthLimitingTextInputFormatter(18),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          if (value == _originalMaskedCpf) return null;

                          final digits = value.replaceAll(RegExp(r'\D'), '');
                          if (digits.length == 11) {
                            if (!ValueUtils.validateCPF(digits)) {
                              return 'CPF inválido';
                            }
                          } else if (digits.length == 14) {
                            if (!ValueUtils.validateCNPJ(digits)) {
                              return 'CNPJ inválido';
                            }
                          } else {
                            return 'CPF deve ter 11 dígitos, CNPJ 14 dígitos';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              loading: () =>
                  const Center(child: ShimmerBlock(width: 20, height: 20)),
              error: (err, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    Spacing.vMd,
                    Text(
                      'Erro ao carregar perfil',
                      style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
