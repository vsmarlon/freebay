import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'app_dialog_actions.dart';
import 'app_dialog_header.dart';

class AppDialogBody extends StatelessWidget {
  final String? logoAsset;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final String? dismissText;
  final String? okText;
  final FutureOr<void> Function()? onDismiss;
  final FutureOr<void> Function()? onOk;
  final bool isError;
  final bool isSuccess;
  final bool showCloseButton;
  final VoidCallback? onClose;
  final List<Widget>? customActions;

  const AppDialogBody({
    super.key,
    this.logoAsset,
    this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.dismissText,
    this.okText,
    this.onDismiss,
    this.onOk,
    this.isError = false,
    this.isSuccess = false,
    this.showCloseButton = false,
    this.onClose,
    this.customActions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDialogHeader(
            logoAsset: logoAsset,
            icon: icon,
            iconColor: iconColor,
            title: title,
            subtitle: subtitle,
            showCloseButton: showCloseButton,
            onClose: onClose,
          ),
          Spacing.vLg,
          customActions != null
              ? Row(children: customActions!)
              : AppDialogActions(
                  dismissText: dismissText,
                  okText: okText,
                  onDismiss: onDismiss,
                  onOk: onOk,
                  isError: isError,
                  isSuccess: isSuccess,
                ),
        ],
      ),
    );
  }
}
