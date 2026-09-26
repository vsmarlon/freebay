part of 'auth_controller.dart';

mixin AuthGoogleAuthentication on Notifier<AsyncValue<UserEntity?>> {
  void _completeCredentialAuth(Either<Failure, UserEntity> result);

  bool _isGoogleSignInInitialized = false;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    final serverClientId = AppConfig.googleServerClientId;
    if (serverClientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(serverClientId: serverClientId);
    } else {
      await GoogleSignIn.instance.initialize();
    }
    _isGoogleSignInInitialized = true;
  }

  Future<void> googleLogin() async {
    AuthSessionCoordinator.beginAuthentication();
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

      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final String? idToken = googleUser.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        ErrorReporter.report(
          'google-signin',
          StateError('idToken ausente — serverClientId != Web Client ID?'),
        );
        _setGoogleError();
        return;
      }

      final result = await ref.read(googleAuthUsecaseProvider)(idToken);
      _completeCredentialAuth(result);
    } on GoogleSignInException catch (e, stack) {
      debugPrint(
        '[GoogleSignIn] code=${e.code.name} description=${e.description}',
      );
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        state = const AsyncValue.data(null);
        return;
      }
      ErrorReporter.report('google-signin', e, stack);
      _setGoogleError();
    } catch (e, stack) {
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
