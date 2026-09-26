import 'package:flutter/cupertino.dart';
import '../tokens/app_colors.dart';
import '../tokens/theme_extension.dart';

class BrutalistCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const BrutalistCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoCheckbox(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primaryContainer,
      checkColor: AppColors.onPrimary,
      side: BorderSide(color: context.borderColor, width: 2),
    );
  }
}
