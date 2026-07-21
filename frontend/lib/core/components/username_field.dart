import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/theme/app_colors.dart';
import 'package:freebay/core/utils/value_utils.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';

enum UsernameFieldStatus { idle, checking, available, taken, invalid }

/// Username input with a debounced live availability check against
/// GET /auth/username-available. Pass [initialUsername] in edit flows so the
/// field treats the user's own current username as valid (no self-conflict).
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
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final candidate = value.trim().toLowerCase();

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
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await ref
          .read(authRepositoryProvider)
          .checkUsernameAvailable(candidate);
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _status = UsernameFieldStatus.idle),
        (available) => setState(() {
          _status = available
              ? UsernameFieldStatus.available
              : UsernameFieldStatus.taken;
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
        return const Icon(Icons.check_circle, color: Colors.green);
      case UsernameFieldStatus.taken:
      case UsernameFieldStatus.invalid:
        return const Icon(Icons.cancel, color: AppColors.error);
      case UsernameFieldStatus.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
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
    );
  }
}
