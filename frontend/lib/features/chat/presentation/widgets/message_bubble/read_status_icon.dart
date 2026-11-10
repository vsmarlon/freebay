import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';

class ReadStatusIcon extends StatelessWidget {
  final bool isRead;
  final bool isDelivered;

  const ReadStatusIcon({
    super.key,
    required this.isRead,
    required this.isDelivered,
  });

  @override
  Widget build(BuildContext context) {
    if (isRead) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 14, color: AppColors.primaryContainer),
        ],
      );
    }
    if (isDelivered) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 14, color: context.textSecondary),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(Icons.done, size: 14, color: context.textSecondary)],
    );
  }
}
