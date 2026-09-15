import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freebay/shared/services/session_timeout.dart';
import 'package:freebay/shared/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService.init();
  });

  test('suppresses duplicate expiry notifications', () async {
    var expiries = 0;
    final timeout = SessionTimeout(
      isAuthenticated: () => true,
      onExpired: () => expiries++,
    );
    addTearDown(timeout.dispose);

    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(
      'last_active_at',
      DateTime.now().subtract(kSessionIdleTimeout).millisecondsSinceEpoch,
    );
    timeout.didChangeAppLifecycleState(AppLifecycleState.resumed);
    timeout.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(expiries, 1);
  });
}
