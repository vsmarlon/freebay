import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/utils/value_utils.dart';

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
  String? _ownerId;
  String? _seededOwnerId;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _ownerId = ref.read(authControllerProvider).asData?.value?.id;
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

  void _clearProfileData(String? ownerId) {
    _ownerId = ownerId;
    _seededOwnerId = null;
    _profileLoaded = false;
    _originalUsername = '';
    _originalMaskedCpf = '';
    _displayNameController.clear();
    _usernameController.clear();
    _bioController.clear();
    _cityController.clear();
    _stateController.clear();
    _cpfController.clear();
  }

  void _seedProfileData(UserEntity user, String ownerId) {
    if (!mounted || _ownerId != ownerId || user.id != ownerId) return;
    if (_seededOwnerId == ownerId) return;
    _seededOwnerId = ownerId;
    _profileLoaded = true;
    _displayNameController.text = user.displayName ?? '';
    _originalUsername = (user.username ?? '').toLowerCase();
    _usernameController.text = _originalUsername;
    _bioController.text = user.bio ?? '';
    _cityController.text = user.city ?? '';
    _stateController.text = user.state ?? '';
    _originalMaskedCpf = user.cpf ?? '';
    _cpfController.text = _originalMaskedCpf;
    setState(() {});
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
    final ownerId = _ownerId;
    if (!_profileLoaded ||
        ownerId == null ||
        !_formKey.currentState!.validate()) {
      return;
    }

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

      if (!mounted ||
          ref.read(authControllerProvider).asData?.value?.id != ownerId) {
        return;
      }

      result.fold((failure) => AppSnackbar.handleFailure(context, failure), (
        updatedUser,
      ) {
        if (updatedUser.id != ownerId) return;
        ref.read(authControllerProvider.notifier).setUser(updatedUser);
        ref.invalidate(profileFutureProvider('me'));
        context.pop();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final auth = ref.watch(authControllerProvider);
    final currentOwnerId = auth.asData?.value?.id;
    ref.listen(authControllerProvider, (_, next) {
      final nextOwnerId = next.asData?.value?.id;
      if (_ownerId == nextOwnerId) return;
      _clearProfileData(nextOwnerId);
      if (mounted) setState(() {});
    });
    ref.listen(profileFutureProvider('me'), (_, next) {
      final user = next.asData?.value;
      final ownerId = ref.read(authControllerProvider).asData?.value?.id;
      if (user != null && ownerId != null) _seedProfileData(user, ownerId);
    });
    if (_ownerId != currentOwnerId) _clearProfileData(currentOwnerId);
    final profileAsync = ref.watch(profileFutureProvider('me'));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: Column(
          children: [
            PageHeader(
              text: strings.profileEdit.toUpperCase(),
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
              actions: [
                InkWell(
                  onTap: _isLoading || !_profileLoaded ? null : _saveProfile,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: _isLoading
                        ? const ShimmerBlock(width: 80, height: 80)
                        : Text(
                            strings.commonSave,
                            style: const TextStyle(
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
                          label: strings.profileName,
                          hint: strings.profileNameHint,
                          maxLength: 50,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return strings.authNameRequired;
                            }
                            if (value.trim().length < 2) {
                              return strings.profileNameMinLength;
                            }
                            if (!ValueUtils.validateDisplayName(value)) {
                              return strings.authNameInvalid;
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
                          label: strings.profileBio,
                          hint: strings.profileBioHint,
                          maxLines: 3,
                          maxLength: 150,
                        ),
                        Spacing.vLg,
                        AppTextField(
                          controller: _cityController,
                          label: strings.profileCity,
                          hint: strings.profileCityHint,
                        ),
                        Spacing.vLg,
                        AppTextField(
                          controller: _stateController,
                          label: strings.profileState,
                          hint: strings.profileStateHint,
                        ),
                        Spacing.vLg,
                        AppTextField(
                          controller: _cpfController,
                          label: strings.profileTaxId,
                          hint: strings.profileTaxIdHint,
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
                                return strings.paymentInvalidCpfCnpj;
                              }
                            } else if (digits.length == 14) {
                              if (!ValueUtils.validateCNPJ(digits)) {
                                return strings.paymentInvalidCpfCnpj;
                              }
                            } else {
                              return strings.profileTaxIdLengthInvalid;
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
                        strings.profileEditLoadError,
                        style: TextStyle(color: context.textPrimary),
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
