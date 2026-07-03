import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/components/app_button.dart';
import 'package:freebay/core/components/app_snackbar.dart';
import 'package:freebay/core/components/app_text_field.dart';
import 'package:freebay/core/components/brutalist_bottom_sheet.dart';
import 'package:freebay/core/components/spacing.dart';
import 'package:freebay/features/bug_report/presentation/providers/bug_report_provider.dart';

Future<void> showBugReportSheet(
  BuildContext context, {
  String? prefillDescription,
  String? screenContext,
}) {
  return showBrutalistSheet(
    context: context,
    title: 'Reportar problema',
    builder: (sheetContext) => _BugReportSheetContent(
      prefillDescription: prefillDescription,
      screenContext: screenContext,
    ),
  );
}

class _BugReportSheetContent extends ConsumerStatefulWidget {
  final String? prefillDescription;
  final String? screenContext;

  const _BugReportSheetContent({
    this.prefillDescription,
    this.screenContext,
  });

  @override
  ConsumerState<_BugReportSheetContent> createState() =>
      _BugReportSheetContentState();
}

class _BugReportSheetContentState
    extends ConsumerState<_BugReportSheetContent> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.prefillDescription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _platform {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  Future<void> _submit() async {
    final description = _controller.text.trim();
    if (description.isEmpty) {
      AppSnackbar.error(context, 'Descreva o problema antes de enviar.');
      return;
    }

    setState(() => _isSubmitting = true);
    final usecase = ref.read(createBugReportUsecaseProvider);
    final result = await usecase(
      description: description,
      platform: _platform,
      screenContext: widget.screenContext,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      (failure) => AppSnackbar.error(context, failure.message),
      (_) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Relatório enviado. Obrigado!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: 'O que aconteceu?',
          controller: _controller,
          maxLines: 4,
        ),
        Spacing.vLg,
        AppButton(
          label: 'Enviar',
          isLoading: _isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}
