import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/theme_extension.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final IconData? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool enabled;
  final FocusNode? focusNode;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onFieldSubmitted,
    this.validator,
    this.inputFormatters,
    this.prefixIcon,
    this.suffix,
    this.suffixIcon,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.enabled = true,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    Widget? builtSuffix = widget.suffixIcon ?? widget.suffix;

    if (widget.showPasswordToggle) {
      builtSuffix = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off : Icons.visibility,
          color: AppColors.mediumGray,
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
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted ?? widget.onSubmitted,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      style: AppTypography.bodyLarge.copyWith(color: context.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label?.isNotEmpty == true ? widget.label : null,
        labelStyle: widget.label?.isNotEmpty == true
            ? const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontWeight: FontWeight.w500,
                color: AppColors.mediumGray,
              )
            : null,
        hintText: widget.hint,
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.mediumGray),
        errorText: widget.errorText,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon, color: AppColors.mediumGray) : null,
        suffixIcon: builtSuffix,
        border: const UnderlineInputBorder(),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.mediumGray),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.accentAmber, width: 2.0),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2.0),
        ),
      ),
    );
  }
}
