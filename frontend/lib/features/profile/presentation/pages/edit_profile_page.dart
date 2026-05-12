import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/theme/theme_extension.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _cpfController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileAsync = ref.read(profileFutureProvider('me'));
    profileAsync.whenData((user) {
      _displayNameController.text = user.displayName ?? '';
      _bioController.text = user.bio ?? '';
      _cityController.text = user.city ?? '';
      _stateController.text = user.state ?? '';
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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
      final cpfDigits = _cpfController.text.replaceAll(RegExp(r'\D'), '');
      final result = await repository.updateProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty
            ? null
            : _stateController.text.trim(),
        cpf: cpfDigits.isEmpty ? null : cpfDigits,
      );

      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          );
        },
        (_) {
          ref.invalidate(profileFutureProvider('me'));
          ref.invalidate(authControllerProvider);
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
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: context.appBarColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: context.textPrimary,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          InkWell(
            onTap: _isLoading ? null : _saveProfile,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Salvar',
                      style: TextStyle(
                        color: AppColors.primaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nome',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    hintText: 'Seu nome',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                const SizedBox(height: 24),
                Text(
                  'Bio',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 150,
                  decoration: InputDecoration(
                    hintText: 'Conte um pouco sobre você',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Cidade',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    hintText: 'Sua cidade',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Estado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.white : AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _stateController,
                  decoration: InputDecoration(
                    hintText: 'Seu estado',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'CPF / CNPJ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.darkGray,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppColors.primaryContainer,
                      child: const Text(
                        'Obrigatório para compras',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cpfController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
                  decoration: InputDecoration(
                    hintText: 'Somente números (CPF: 11 dígitos, CNPJ: 14)',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    if (digits.length != 11 && digits.length != 14) {
                      return 'CPF deve ter 11 dígitos, CNPJ 14 dígitos';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryPurple),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
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
    );
  }
}
