import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';
import 'package:freebay/shared/services/storage_service.dart';

/// Keeps protected routes mounted but inaccessible while biometric reauth runs.
class SessionLockGate extends StatefulWidget {
  const SessionLockGate({
    required this.accountId,
    required this.lockAfter,
    required this.onReauthenticate,
    required this.onUsePassword,
    required this.child,
    this.isPublicRoute = false,
    this.isExternalActivity = false,
    this.now = DateTime.now,
    super.key,
  });

  final String? accountId;
  final Duration? lockAfter;
  final Future<bool> Function(String accountId) onReauthenticate;
  final VoidCallback onUsePassword;
  final Widget child;
  final bool isPublicRoute;
  final bool isExternalActivity;
  final DateTime Function() now;

  @override
  State<SessionLockGate> createState() => _SessionLockGateState();
}

class _SessionLockGateState extends State<SessionLockGate>
    with WidgetsBindingObserver {
  DateTime _lastActivity = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _timer;
  String? _accountId;
  int _generation = 0;
  int _lastPersistedAtMs = 0;
  bool _locked = false;
  bool _requestInFlight = false;
  bool _promptAttempted = false;
  bool get _exempt => widget.isPublicRoute || widget.isExternalActivity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _accountId = widget.accountId;
    if (_accountId != null) {
      final savedAt = StorageService.getSessionLockActivityAtSync(_accountId!);
      _lastActivity = savedAt == null
          ? widget.now()
          : DateTime.fromMillisecondsSinceEpoch(savedAt);
      _lastPersistedAtMs = _lastActivity.millisecondsSinceEpoch;
      _evaluateLock(prompt: true);
      if (savedAt == null) _persistActivity(_accountId!, _lastActivity);
    }
    _armTimer();
  }

  @override
  void didUpdateWidget(covariant SessionLockGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountId != widget.accountId) {
      _generation++;
      _accountId = widget.accountId;
      _locked = false;
      _requestInFlight = false;
      _promptAttempted = false;
      if (_accountId != null) {
        // A null -> id transition is a fresh authentication, not a restore:
        // hydrating the stored timestamp would lock the new session on entry.
        final savedAt = oldWidget.accountId == null
            ? null
            : StorageService.getSessionLockActivityAtSync(_accountId!);
        _lastActivity = savedAt == null
            ? widget.now()
            : DateTime.fromMillisecondsSinceEpoch(savedAt);
        _lastPersistedAtMs = _lastActivity.millisecondsSinceEpoch;
        _evaluateLock(prompt: true);
        if (savedAt == null) _persistActivity(_accountId!, _lastActivity);
      }
    }
    if (oldWidget.lockAfter != widget.lockAfter) {
      if (oldWidget.lockAfter == null && widget.lockAfter != null) {
        _lastActivity = widget.now();
        if (_accountId != null) _persistActivity(_accountId!, _lastActivity);
      }
      if (widget.lockAfter == null) {
        _locked = false;
        _promptAttempted = false;
      } else {
        _evaluateLock(prompt: true);
      }
    }
    if (_exempt && !_locked) {
      _timer?.cancel();
    } else if (!_exempt) {
      _evaluateLock(prompt: true);
    }
    _armTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _evaluateLock(prompt: true);
      _armTimer();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _evaluateLock(prompt: false);
      _timer?.cancel();
    }
  }

  void _recordActivity() {
    final accountId = _accountId;
    if (accountId == null || _locked || _exempt) return;
    _lastActivity = widget.now();
    _promptAttempted = false;
    if (_lastActivity.millisecondsSinceEpoch - _lastPersistedAtMs >= 5000) {
      _persistActivity(accountId, _lastActivity);
    }
    _armTimer();
  }

  void _persistActivity(String accountId, DateTime time) {
    _lastPersistedAtMs = time.millisecondsSinceEpoch;
    unawaited(
      StorageService.setSessionLockActivityAt(
        accountId,
        time.millisecondsSinceEpoch,
      ),
    );
  }

  void _armTimer() {
    _timer?.cancel();
    final timeout = widget.lockAfter;
    if (timeout == null || _accountId == null || _locked || _exempt) return;
    final remaining = _lastActivity.add(timeout).difference(widget.now());
    _timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
      _evaluateLock(prompt: true);
      _armTimer();
    });
  }

  void _evaluateLock({required bool prompt}) {
    final timeout = widget.lockAfter;
    if (timeout == null || _accountId == null || _exempt) return;
    if (!widget.now().isBefore(_lastActivity.add(timeout)) && !_locked) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() => _locked = true);
    }
    if (_locked && prompt && !_promptAttempted) {
      _promptAttempted = true;
      final generation = _generation;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _generation || _exempt || !_locked) {
          return;
        }
        unawaited(_attemptUnlock());
      });
    }
  }

  Future<void> _attemptUnlock() async {
    final accountId = _accountId;
    if (accountId == null || _requestInFlight || !_locked || _exempt) return;
    final generation = _generation;
    setState(() => _requestInFlight = true);
    var accepted = false;
    try {
      accepted = await widget.onReauthenticate(accountId);
    } catch (_) {
      // Offline, cancellation, lockout and provider failures stay fail-closed.
    }
    if (!mounted || generation != _generation || accountId != _accountId) {
      return;
    }
    setState(() {
      _requestInFlight = false;
      if (accepted) {
        _locked = false;
        _lastActivity = widget.now();
        _promptAttempted = false;
      }
    });
    if (accepted) {
      _persistActivity(accountId, _lastActivity);
      _armTimer();
    }
  }

  void _retry() {
    if (_requestInFlight) return;
    _promptAttempted = true;
    unawaited(_attemptUnlock());
  }

  @override
  Widget build(BuildContext context) => Focus(
    onKeyEvent: (_, _) {
      _recordActivity();
      return KeyEventResult.ignored;
    },
    child: Listener(
      onPointerDown: (_) => _recordActivity(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            ignoring: _locked && !widget.isPublicRoute,
            child: ExcludeSemantics(
              excluding: _locked && !widget.isPublicRoute,
              child: ExcludeFocus(
                excluding: _locked && !widget.isPublicRoute,
                child: widget.child,
              ),
            ),
          ),
          if (_locked && !widget.isPublicRoute)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 600,
                      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
                    ),
                    child: Material(
                      color: context.surfaceColor,
                      child: Semantics(
                        scopesRoute: true,
                        namesRoute: true,
                        explicitChildNodes: true,
                        label: l10n(context).profileBiometry,
                        child: BrutalistSheetScaffold(
                          title: l10n(context).profileBiometry,
                          showDragHandle: false,
                          builder: (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n(context).sessionLockRequiredDescription,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: context.textSecondary,
                                ),
                              ),
                              Spacing.vLg,
                              AppButton(
                                label: l10n(context).authUseBiometrics,
                                icon: Icons.fingerprint,
                                isLoading: _requestInFlight,
                                onPressed: _retry,
                                width: double.infinity,
                              ),
                              Spacing.vSm,
                              AppButton(
                                label: l10n(context).sessionLockUsePassword,
                                variant: AppButtonVariant.ghost,
                                onPressed: _requestInFlight
                                    ? null
                                    : widget.onUsePassword,
                                width: double.infinity,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
