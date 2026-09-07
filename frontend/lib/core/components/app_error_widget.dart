import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'empty_state.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      child: EmptyState.error(message: details.exception.toString()),
    );
  }
}
