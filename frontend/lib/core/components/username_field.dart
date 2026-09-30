import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

const usernameAvailabilityDebounce = Duration(milliseconds: 500);

enum UsernameFieldStatus {
  idle,
  checking,
  available,
  taken,
  invalid,
  unavailable,
}

class UsernameField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String? initialUsername;
  final String label;

  const UsernameField({
    super.key,
    required this.controller,
    this.initialUsername,
    this.label = 'Nome de usuário',
  });

  @override
  ConsumerState<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends ConsumerState<UsernameField> {
  UsernameFieldStatus _status = UsernameFieldStatus.idle;
  List<String> _suggestions = [];
  int _requestVersion = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final version = ++_requestVersion;
    final candidate = value.trim().toLowerCase();
    _suggestions = [];

    if (candidate == widget.initialUsername) {
      setState(() => _status = UsernameFieldStatus.idle);
      return;
    }
    if (!ValueUtils.validateUsername(candidate)) {
      setState(() {
        _status = candidate.isEmpty
            ? UsernameFieldStatus.idle
            : UsernameFieldStatus.invalid;
      });
      return;
    }

    setState(() => _status = UsernameFieldStatus.checking);
    _debounce = Timer(usernameAvailabilityDebounce, () async {
      final result = await ref
          .read(authRepositoryProvider)
          .checkUsernameAvailable(candidate);
      if (!mounted || version != _requestVersion) return;
      result.fold(
        (_) => setState(() => _status = UsernameFieldStatus.unavailable),
        (availability) => setState(() {
          _status = availability.available
              ? UsernameFieldStatus.available
              : UsernameFieldStatus.taken;
          _suggestions = availability.suggestions;
        }),
      );
    });
  }

  Widget? _suffixIcon() {
    switch (_status) {
      case UsernameFieldStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case UsernameFieldStatus.available:
        return const Icon(Icons.check_circle, color: AppColors.success);
      case UsernameFieldStatus.taken:
      case UsernameFieldStatus.invalid:
        return const Icon(Icons.cancel, color: AppColors.error);
      case UsernameFieldStatus.idle:
      case UsernameFieldStatus.unavailable:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedback = switch (_status) {
      UsernameFieldStatus.idle => null,
      UsernameFieldStatus.checking => 'Verificando nome de usuário…',
      UsernameFieldStatus.available => 'Nome de usuário disponível',
      UsernameFieldStatus.taken => 'Nome de usuário em uso',
      UsernameFieldStatus.invalid => 'Use 3-20 letras, números ou _',
      UsernameFieldStatus.unavailable => 'Não foi possível verificar agora',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: widget.controller,
          label: widget.label,
          hint: '@usuario',
          prefixIcon: Icons.alternate_email,
          suffixIcon: _suffixIcon(),
          onChanged: _onChanged,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
            LengthLimitingTextInputFormatter(20),
            TextInputFormatter.withFunction(
              (oldValue, newValue) =>
                  newValue.copyWith(text: newValue.text.toLowerCase()),
            ),
          ],
          validator: (v) {
            final value = v?.trim().toLowerCase() ?? '';
            if (value.isEmpty) return 'Escolha um nome de usuário';
            if (!ValueUtils.validateUsername(value)) {
              return '3-20 caracteres: letras minúsculas, números e _';
            }
            if (value != widget.initialUsername &&
                _status == UsernameFieldStatus.taken) {
              return 'Nome de usuário já está em uso';
            }
            return null;
          },
        ),
        if (feedback != null)
          Text(
            feedback,
            style: AppTypography.bodySmall.copyWith(
              color: switch (_status) {
                UsernameFieldStatus.available => AppColors.success,
                UsernameFieldStatus.taken ||
                UsernameFieldStatus.invalid => AppColors.error,
                _ => context.textSecondary,
              },
            ),
          ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final suggestion in _suggestions)
                AppButton(
                  label: '@$suggestion',
                  variant: AppButtonVariant.ghost,
                  size: AppButtonSize.compact,
                  onPressed: () {
                    widget.controller.value = TextEditingValue(
                      text: suggestion,
                      selection: TextSelection.collapsed(
                        offset: suggestion.length,
                      ),
                    );
                    _onChanged(suggestion);
                  },
                ),
            ],
          ),
        ],
      ],
    );
  }
}
