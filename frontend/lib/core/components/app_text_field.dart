import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool showPasswordToggle;
  final bool clearOnFocusLost;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool enabled;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.clearOnFocusLost = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.enabled = true,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  String? _previousValue;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      _obscureText = widget.obscureText;
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.clearOnFocusLost) {
      final currentValue = widget.controller?.text ?? '';
      if (currentValue.isNotEmpty && _previousValue != currentValue) {
        widget.controller?.clear();
      }
    }
    if (_focusNode.hasFocus) {
      _previousValue = widget.controller?.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget? effectiveSuffixIcon = widget.suffixIcon;
    if (widget.showPasswordToggle && widget.obscureText) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      maxLines: widget.showPasswordToggle ? 1 : widget.maxLines,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      style: TextStyle(
        color: isDark ? AppColors.white : AppColors.darkGray,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon,
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray)
            : null,
        suffixIcon: effectiveSuffixIcon,
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
      ),
    );
  }
}
