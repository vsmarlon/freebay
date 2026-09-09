import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freebay/shared/services/storage_service.dart';

const Duration kSessionIdleTimeout = Duration(minutes: 12);

/// Expires an authenticated session after [kSessionIdleTimeout] of inactivity,
/// measured on the wall clock so time spent in the background counts too.
///
/// [onExpired] is the single expiry path — `HttpClient.onAuthLost` calls it as
/// well, so a refresh failure and an idle timeout cannot raise two dialogs.
class SessionTimeout with WidgetsBindingObserver {
  SessionTimeout({required this.onExpired, required this.isAuthenticated});

  final VoidCallback onExpired;
  final bool Function() isAuthenticated;

  Timer? _timer;
  bool _expired = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    touch();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  /// Called on every pointer down and after a successful login.
  void touch() {
    if (!isAuthenticated()) return;
    _expired = false;
    StorageService.touchLastActiveAt();
    _timer?.cancel();
    _timer = Timer(kSessionIdleTimeout, _expire);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _timer?.cancel();
      return;
    }
    if (!isAuthenticated()) return;
    final last = StorageService.lastActiveAtSync();
    if (last != null &&
        DateTime.now().difference(last) >= kSessionIdleTimeout) {
      _expire();
      return;
    }
    touch();
  }

  void _expire() {
    if (_expired || !isAuthenticated()) return;
    _expired = true;
    _timer?.cancel();
    onExpired();
  }
}
