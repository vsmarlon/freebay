import 'package:flutter/material.dart';
import 'package:freebay/core/theme/app_colors.dart';

class ErrorIndicator extends StatelessWidget {
  final VoidCallback onTap;

  const ErrorIndicator({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: Icon(
          Icons.bug_report_outlined,
          color: AppColors.error,
          size: 20,
        ),
      ),
    );
  }
}
