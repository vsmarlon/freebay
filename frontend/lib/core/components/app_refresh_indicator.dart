import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';

class AppRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final ScrollNotificationPredicate notificationPredicate;

  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.notificationPredicate = defaultScrollNotificationPredicate,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primaryContainer,
      notificationPredicate: notificationPredicate,
      child: child,
    );
  }
}
