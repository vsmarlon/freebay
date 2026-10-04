import 'package:freebay/shared/services/http_client.dart';
import 'package:freebay/shared/services/storage_service.dart';

class AuthSessionCoordinator {
  static Future<void> _operation = Future<void>.value();
  static int _authenticationAttempt = 0;

  static int get currentAuthenticationAttempt => _authenticationAttempt;

  static bool isCurrentAttempt(int attempt) =>
      attempt == _authenticationAttempt;

  static int beginAuthentication() {
    _authenticationAttempt++;
    HttpClient.suspendRefresh();
    return _authenticationAttempt;
  }

  static Future<bool> establishSession({
    required bool Function() canEstablish,
  }) => serialize(() async {
    if (!canEstablish()) return false;
    HttpClient.establishSession();
    return true;
  });

  static Future<bool> installTokensAndEstablish({
    required int attempt,
    required String token,
    required String? refreshToken,
    required Future<Future<void> Function()> Function() captureRollback,
    Future<void> Function()? afterAuthenticationSideEffects,
    required Future<void> Function() afterInstall,
  }) => serialize(() async {
    if (!isCurrentAttempt(attempt)) return false;
    final rollback = await captureRollback();
    if (!isCurrentAttempt(attempt)) return false;
    Future<void> undoInstall() async {
      try {
        await rollback();
      } finally {
        await _clearInstalledTokens(token, refreshToken);
      }
    }

    try {
      await StorageService.saveTokenPair(token, refreshToken);
      if (!isCurrentAttempt(attempt)) {
        await undoInstall();
        return false;
      }
      await afterInstall();
      await afterAuthenticationSideEffects?.call();
      if (!isCurrentAttempt(attempt)) {
        await undoInstall();
        return false;
      }
      HttpClient.establishSession();
      return true;
    } catch (_) {
      await undoInstall();
      rethrow;
    }
  });

  static Future<void> _clearInstalledTokens(
    String token,
    String? refreshToken,
  ) async {
    await StorageService.clearTokenIf(token);
    if (refreshToken != null) {
      await StorageService.clearRefreshTokenIf(refreshToken);
    }
  }

  static Future<T> serialize<T>(Future<T> Function() operation) {
    final result = _operation.then((_) => operation());
    _operation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
