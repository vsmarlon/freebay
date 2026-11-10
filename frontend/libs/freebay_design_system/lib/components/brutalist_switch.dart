import 'package:flutter/cupertino.dart';
import '../tokens/app_colors.dart';
import '../tokens/theme_extension.dart';

class BrutalistSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const BrutalistSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primaryContainer,
      inactiveTrackColor: context.borderSoftColor,
      thumbColor: AppColors.white,
    );
  }
}
