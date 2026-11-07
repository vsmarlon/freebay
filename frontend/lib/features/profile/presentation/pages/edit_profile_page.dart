import 'dart:async';

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
  final _verificationCodeController = TextEditingController();
  bool _isLoading = false;
  String? _challengeCpf;
  DateTime? _challengeExpiresAt;
  DateTime? _challengeResendAt;
  String _originalMaskedCpf = '';
  String _originalUsername = '';
  String? _ownerId;
  String? _seededOwnerId;
  bool _profileLoaded = false;
  Timer? _challengeTimer;

  @override
  void initState() {
    super.initState();
    _ownerId = ref.read(authControllerProvider).asData?.value?.id;
    _cpfController.addListener(_onCpfChanged);
  }

  void _onCpfChanged() {
    final text = _cpfController.text;
    final currentDigits = text.replaceAll(RegExp(r'\D'), '');
    if (_challengeCpf != null && currentDigits != _challengeCpf) {
      _clearChallenge();
      if (mounted) setState(() {});
    }
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

  void _clearChallenge() {
    _challengeTimer?.cancel();
    _challengeTimer = null;
    _challengeCpf = null;
    _challengeExpiresAt = null;
    _challengeResendAt = null;
    _verificationCodeController.clear();
  }

  void _clearProfileData(String? ownerId) {
    _ownerId = ownerId;
    _seededOwnerId = null;
    _profileLoaded = false;
    _clearChallenge();
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
    _verificationCodeController.dispose();
    _challengeTimer?.cancel();
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

      if (cpfDigits != null && cpfDigits.isNotEmpty) {
        final challengeValid =
            _challengeCpf == cpfDigits &&
            _challengeExpiresAt != null &&
            _challengeExpiresAt!.isAfter(DateTime.now()) &&
            RegExp(r'^\d{6}$').hasMatch(_verificationCodeController.text);
        if (!challengeValid) {
          if (_challengeCpf == cpfDigits &&
              _challengeResendAt != null &&
              _challengeResendAt!.isAfter(DateTime.now()) &&
              _challengeExpiresAt!.isAfter(DateTime.now())) {
            return;
          }
          final challenge = await repository.requestProfileVerification(
            cpf: cpfDigits,
            locale: Localizations.localeOf(context).languageCode == 'en'
                ? 'en'
                : 'pt-BR',
          );
          if (!mounted ||
              ref.read(authControllerProvider).asData?.value?.id != ownerId ||
              _cpfController.text.replaceAll(RegExp(r'\D'), '') != cpfDigits) {
            return;
          }
          var requested = false;
          challenge.fold(
            (failure) => AppSnackbar.handleFailure(context, failure),
            (value) {
              requested = true;
              setState(() {
                _challengeCpf = cpfDigits;
                _challengeExpiresAt = DateTime.now().add(
                  Duration(seconds: value.expiresIn),
                );
                _challengeResendAt = DateTime.now().add(
                  Duration(seconds: value.resendAfter),
                );
              });
              _challengeTimer?.cancel();
              _challengeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
                if (_challengeExpiresAt?.isAfter(DateTime.now()) != true) {
                  _challengeTimer?.cancel();
                }
                if (mounted) setState(() {});
              });
            },
          );
          if (!requested) _clearChallenge();
          return;
        }
      }

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
        profileVerificationCode: cpfDigits == null || cpfDigits.isEmpty
            ? null
            : _verificationCodeController.text,
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
        if (cpfDigits != null && cpfDigits.isNotEmpty) _clearChallenge();
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
                        Spacing.vSm,
                        _profileSection(
                          title: strings.profileEditIdentitySection,
                          children: [
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
                            if (_challengeCpf != null) ...[
                              Text(strings.profileDocumentVerificationCodeSent),
                              if (_challengeExpiresAt != null)
                                Text(
                                  strings.profileDocumentVerificationExpiry(
                                    _challengeExpiresAt!
                                        .difference(DateTime.now())
                                        .inSeconds
                                        .clamp(0, 1 << 31),
                                  ),
                                ),
                              if (_challengeResendAt != null &&
                                  _challengeResendAt!.isAfter(DateTime.now()))
                                Text(
                                  strings.profileDocumentVerificationCooldown(
                                    _challengeResendAt!
                                        .difference(DateTime.now())
                                        .inSeconds
                                        .clamp(0, 1 << 31),
                                  ),
                                )
                              else
                                AppButton(
                                  label: strings.commonRetry,
                                  variant: AppButtonVariant.ghost,
                                  size: AppButtonSize.compact,
                                  onPressed: _isLoading ? null : _saveProfile,
                                ),
                              Spacing.vMd,
                              AppTextField(
                                key: const ValueKey(
                                  'profileVerificationCodeField',
                                ),
                                controller: _verificationCodeController,
                                label: strings.profileVerificationCode,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                              ),
                            ],
                            Spacing.vMd,
                            UsernameField(
                              controller: _usernameController,
                              initialUsername: _originalUsername,
                            ),
                            Spacing.vMd,
                            AppTextField(
                              controller: _bioController,
                              label: strings.profileBio,
                              hint: strings.profileBioHint,
                              maxLines: 3,
                              maxLength: 150,
                            ),
                          ],
                        ),
                        Spacing.vMd,
                        _profileSection(
                          title: strings.profileEditLocationSection,
                          children: [
                            AppTextField(
                              controller: _cityController,
                              label: strings.profileCity,
                              hint: strings.profileCityHint,
                            ),
                            Spacing.vMd,
                            AppTextField(
                              controller: _stateController,
                              label: strings.profileState,
                              hint: strings.profileStateHint,
                            ),
                          ],
                        ),
                        Spacing.vMd,
                        _profileSection(
                          title: strings.profileEditDocumentSection,
                          children: [
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

                                final digits = value.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
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
                        Spacing.vSm,
                      ],
                    ),
                  ),
                ),
                loading: () =>
                    const Center(child: ShimmerBlock(width: 20, height: 20)),
                error: (err, _) => EmptyState.error(
                  message: strings.profileEditLoadError,
                  onRetry: () => ref.invalidate(profileFutureProvider('me')),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.sm,
                  Spacing.md,
                  Spacing.md,
                ),
                child: AppButton(
                  label: strings.commonSave,
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _isLoading || !_profileLoaded
                      ? null
                      : _saveProfile,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileSection({
    required String title,
    required List<Widget> children,
  }) => BrutalistBox(
    backgroundColor: context.surfaceColor,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.labelLarge.weight(700)),
        Spacing.vMd,
        ...children,
      ],
    ),
  );
}
