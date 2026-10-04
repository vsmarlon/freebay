part of 'auth_controller.dart';

mixin AuthGoogleAuthentication on Notifier<AsyncValue<UserEntity?>> {
  Future<void> _completeCredentialAuth(
    Either<Failure, UserEntity> result, {
    required int attempt,
  });

  static Future<void>? _googleInitialization;

  Future<void> ensureGoogleSignInInitialized() =>
      _googleInitialization ??= _initializeGoogleSignIn();

  Future<void> _initializeGoogleSignIn() async {
    final serverClientId = AppConfig.googleServerClientId;
    if (serverClientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    } else {
      await GoogleSignIn.instance.initialize();
    }
  }

  Future<void> googleLogin() async {
    final sdkAttempt = AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.loading();
    try {
      final serverClientId = AppConfig.googleServerClientId;
      if (serverClientId.isEmpty) {
        ErrorReporter.report(
          'google-signin',
          StateError('GOOGLE_SERVER_CLIENT_ID ausente'),
        );
        _setGoogleError();
        return;
      }

      await ensureGoogleSignInInitialized();
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        ErrorReporter.report(
          'google-signin',
          StateError('idToken ausente — serverClientId != Web Client ID?'),
        );
        _setGoogleError();
        return;
      }

      final request = ref.read(googleAuthUsecaseProvider)((
        idToken: idToken,
        authenticationAttempt: sdkAttempt,
      ));
      final attempt = sdkAttempt;
      final result = await request;
      if (!AuthSessionCoordinator.isCurrentAttempt(attempt)) return;
      await _completeCredentialAuth(result, attempt: attempt);
    } on GoogleSignInException catch (e, stack) {
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      debugPrint('[GoogleSignIn] code=${e.code.name}');
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        state = const AsyncValue.data(null);
        return;
      }
      ErrorReporter.report('google-signin', e, stack);
      _setGoogleError();
    } catch (e, stack) {
      if (!AuthSessionCoordinator.isCurrentAttempt(sdkAttempt)) return;
      ErrorReporter.report('google-signin', e, stack);
      _setGoogleError();
    }
  }

  void _setGoogleError() {
    state = AsyncValue.error(
      const ServerFailure(_googleGenericError),
      StackTrace.current,
    );
  }
}
