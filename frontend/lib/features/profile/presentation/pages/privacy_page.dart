import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/auth.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/shared/config/app_config.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key, this.repository});

  final ProfileRepository? repository;

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  bool _busy = false;

  ProfileRepository get _repository => widget.repository ?? ProfileRepository();

  Future<void> _exportData() async {
    setState(() => _busy = true);
    try {
      final stepUpToken = await StepUpAuthenticator.authorize(
        context,
        ref,
        purpose: 'export_data',
      );
      if (stepUpToken == null || !mounted) return;
      final result = await _repository.exportMyData(stepUpToken: stepUpToken);
      if (!mounted) return;
      await result.fold(
        (failure) async => AppSnackbar.handleFailure(context, failure),
        (data) async {
          // ponytail: share JSON as text to avoid persistent plaintext temp files;
          // very large exports may exceed a platform's share-text limits.
          final renderObject = context.findRenderObject();
          final box = renderObject is RenderBox ? renderObject : null;
          await SharePlus.instance.share(
            ShareParams(
              subject: 'FreeBay account data',
              text: jsonEncode(data),
              sharePositionOrigin: box == null
                  ? null
                  : box.localToGlobal(Offset.zero) & box.size,
            ),
          );
        },
      );
    } catch (_) {
      if (mounted) AppSnackbar.error(context, l10n(context).errorUnknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestDeletion() async {
    var confirmed = false;
    await AppDialog.show<void>(
      context: context,
      title: l10n(context).privacyDeleteConfirmTitle,
      subtitle: l10n(context).privacyDeleteConfirmBody,
      dismissText: l10n(context).commonCancel,
      okText: l10n(context).privacyDeleteAction,
      isError: true,
      onOk: () => confirmed = true,
    );
    if (!confirmed || !mounted || _busy) return;
    setState(() => _busy = true);
    try {
      final stepUpToken = await StepUpAuthenticator.authorize(
        context,
        ref,
        purpose: 'delete_account',
      );
      if (stepUpToken == null || !mounted) return;
      final result = await _repository.requestAccountDeletion(
        stepUpToken: stepUpToken,
      );
      if (!mounted) return;
      await result.fold(
        (failure) async => AppSnackbar.handleFailure(context, failure),
        (_) async {
          await ref.read(authControllerProvider.notifier).forceLogout();
          if (mounted) context.go(AppRoutes.login);
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelDeletion() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await _repository.cancelAccountDeletion();
    if (!mounted) return;
    await result.fold(
      (failure) async {
        AppSnackbar.handleFailure(context, failure);
        if (failure is UnauthorizedFailure && mounted) {
          AppSnackbar.info(context, l10n(context).privacyCancelDeletionRelogin);
        }
      },
      (_) async {
        await ref.read(authControllerProvider.notifier).tryRefreshSession();
        if (mounted) {
          AppSnackbar.success(context, l10n(context).privacyDeletionCancelled);
        }
      },
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openLegalPage(String path) async {
    final base = Uri.tryParse(AppConfig.apiBaseUrl);
    if (base == null || !base.hasAuthority) {
      AppSnackbar.error(context, l10n(context).privacyLegalUnavailable);
      return;
    }
    final uri = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      AppSnackbar.error(context, l10n(context).privacyLegalUnavailable);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    final deletionRequestedAt = ref
        .watch(authControllerProvider)
        .value
        ?.deletionRequestedAt;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              PageHeader(
                text: strings.privacyTitle.toUpperCase(),
                leading: BrutalistIconButton(
                  icon: Icons.arrow_back,
                  semanticLabel: strings.accessibilityBack,
                  onTap: () => context.pop(),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(Spacing.md),
                  children: [
                    Text(strings.privacyScope, style: AppTypography.bodyMedium),
                    Spacing.vMd,
                    AppButton(
                      label: strings.privacyExportAction,
                      isLoading: _busy,
                      onPressed: _busy ? null : _exportData,
                    ),
                    Spacing.vSm,
                    _LegalLink(
                      title: strings.privacyPolicy,
                      onTap: () => _openLegalPage('/legal/privacy.html'),
                    ),
                    _LegalLink(
                      title: strings.privacyTerms,
                      onTap: () => _openLegalPage('/legal/terms.html'),
                    ),
                    _LegalLink(
                      title: strings.privacyDeletionPolicy,
                      onTap: () => _openLegalPage('/legal/delete-account.html'),
                    ),
                    Spacing.vLg,
                    if (deletionRequestedAt != null) ...[
                      Text(
                        strings.privacyDeletionPending(
                          MaterialLocalizations.of(
                            context,
                          ).formatMediumDate(deletionRequestedAt.toLocal()),
                        ),
                        style: AppTypography.bodyMedium,
                      ),
                      Spacing.vSm,
                      AppButton(
                        label: strings.privacyCancelDeletion,
                        isLoading: _busy,
                        onPressed: _busy ? null : _cancelDeletion,
                      ),
                    ] else ...[
                      Text(
                        strings.privacyDeletionExplanation,
                        style: AppTypography.bodyMedium,
                      ),
                      Spacing.vSm,
                      AppButton(
                        label: strings.privacyDeleteAction,
                        variant: AppButtonVariant.danger,
                        isLoading: _busy,
                        onPressed: _busy ? null : _requestDeletion,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title, style: AppTypography.bodyMedium),
    trailing: const Icon(Icons.open_in_new),
    onTap: onTap,
  );
}
