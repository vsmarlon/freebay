import 'package:freebay/shared/services/http_client.dart';

class AuthSessionCoordinator {
  static Future<void> _operation = Future<void>.value();

  static void beginAuthentication() => HttpClient.suspendRefresh();

  static Future<void> establishSession() => serialize(_establishSession);

  static Future<void> _establishSession() async {
    HttpClient.establishSession();
  }

  static Future<void> installTokensAndEstablish(
    Future<void> Function() installTokens,
  ) => serialize(() async {
    await installTokens();
    HttpClient.establishSession();
  });

  static Future<void> serialize(Future<void> Function() operation) {
    final result = _operation.then((_) => operation());
    _operation = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}
