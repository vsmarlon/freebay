part of 'auth_controller.dart';

mixin AuthSessionLifecycle on Notifier<AsyncValue<UserEntity?>> {
  Future<void> _initAuth(int attempt) async {
    if (!ref.mounted) return;
    // Close HTTP auth before any asynchronous consent/storage lookup can run.
    HttpClient.suspendRefresh();
    state = const AsyncValue.loading();
    ref.read(isInitialAuthLoadingProvider.notifier).set(true);

    try {
      final hasSeenOnboarding = StorageService.hasSeenOnboardingSync();
      if (!_isCurrentAuthAttempt(attempt)) return;
      ref.read(hasSeenOnboardingProvider.notifier).set(hasSeenOnboarding);

      final rememberMe = await StorageService.getRememberMe();
      if (!_isCurrentAuthAttempt(attempt)) return;
      if (!rememberMe) {
        await _clearTokensForAttempt(attempt);
        if (!_isCurrentAuthAttempt(attempt)) return;
        state = const AsyncValue.data(null);
        return;
      }

      final biometryEnabled = await ref
          .read(biometryServiceProvider)
          .isEnabled();
      if (!_isCurrentAuthAttempt(attempt)) return;
      if (biometryEnabled) {
        await _clearTokensForAttempt(attempt);
        if (!_isCurrentAuthAttempt(attempt)) return;
        await _tryBiometricLogin(attempt);
        return;
      }
      final token = await StorageService.getToken();
      if (!_isCurrentAuthAttempt(attempt)) return;
      if (token == null) {
        await _tryBiometricLogin(attempt);
        return;
      }

      final admitted = await AuthSessionCoordinator.establishSession(
        canEstablish: () => _isCurrentAuthAttempt(attempt),
      );
      if (!admitted || !_isCurrentAuthAttempt(attempt)) return;
      final result = await ref.read(getCurrentUserUsecaseProvider)();
      if (!_isCurrentAuthAttempt(attempt)) return;
      await result.fold(
        (failure) async {
          if (!_isCurrentAuthAttempt(attempt)) return;
          await _clearTokensForAttempt(attempt);
          if (!_isCurrentAuthAttempt(attempt)) return;
          state = const AsyncValue.data(null);
        },
        (user) async {
          if (!_isCurrentAuthAttempt(attempt)) return;
          await _establishAuthenticatedSession(user, attempt: attempt);
        },
      );
    } catch (_) {
      if (!_isCurrentAuthAttempt(attempt)) return;
      await _clearTokensForAttempt(attempt);
      if (!_isCurrentAuthAttempt(attempt)) return;
      state = const AsyncValue.data(null);
    } finally {
      if (_isCurrentAuthAttempt(attempt)) {
        ref.read(isInitialAuthLoadingProvider.notifier).set(false);
        routerRefreshNotifier.value++;
      }
    }
  }

  Future<void> _tryBiometricLogin(int attempt) async {
    final request = ref.read(biometricLoginUsecaseProvider)(attempt);
    final result = await request;
    if (!_isCurrentAuthAttempt(attempt)) return;
    await result.fold<Future<void>>((failure) async {
      HttpClient.suspendRefresh();
      await _clearTokensForAttempt(attempt);
      if (_isCurrentAuthAttempt(attempt)) state = const AsyncValue.data(null);
    }, (user) => _establishAuthenticatedSession(user, attempt: attempt));
  }

  bool _isCurrentAuthAttempt(int attempt) =>
      ref.mounted && AuthSessionCoordinator.isCurrentAttempt(attempt);

  Future<void> _clearTokensForAttempt(int attempt) =>
      AuthSessionCoordinator.serialize(() async {
        if (_isCurrentAuthAttempt(attempt)) await StorageService.clearTokens();
      });

  Future<void> _establishAuthenticatedSession(
    UserEntity user, {
    required int attempt,
  }) async {
    final established = await AuthSessionCoordinator.establishSession(
      canEstablish: () => _isCurrentAuthAttempt(attempt),
    );
    if (!established || !_isCurrentAuthAttempt(attempt)) return;
    ref.read(cartProvider.notifier).resetForSessionChange();
    state = AsyncValue.data(user);
    try {
      await ref.read(cartProvider.notifier).loadCart();
    } catch (_) {}
  }

  void _invalidateUserProviders() {
    ref.read(feedProvider.notifier).clear();
    ref.read(postSearchProvider.notifier).clear();
    ref.read(likesProvider.notifier).clear();
    ref.read(savesProvider.notifier).clear();
    ref.read(repostsProvider.notifier).clear();
    ref.read(commentLikesProvider.notifier).clear();
    ref.read(userSearchProvider.notifier).clear();
    ref.read(suggestionsProvider.notifier).clear();
    ref.read(walletProvider.notifier).reset();
    ref.read(walletHistoryProvider.notifier).reset();
    ref.read(connectStatusProvider.notifier).reset();
    ref.invalidate(walletProvider);
    ref.invalidate(walletHistoryProvider);
    ref.invalidate(connectStatusProvider);
    ref.read(cartProvider.notifier).resetForSessionChange();
    ref.invalidate(disputeListProvider);
    ref.invalidate(purchasesListProvider);
    ref.invalidate(salesListProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(chatsProvider);
    ref.invalidate(liveChatListProvider);
    ref.invalidate(archivedChatListProvider);
    ref.invalidate(feedProvider);
    ref.invalidate(postSearchProvider);
    ref.invalidate(likesProvider);
    ref.invalidate(savesProvider);
    ref.invalidate(repostsProvider);
    ref.invalidate(commentLikesProvider);
    ref.invalidate(userSearchProvider);
    ref.invalidate(suggestionsProvider);
    ref.invalidate(storiesProvider);
    ref.invalidate(userStoriesProvider);
  }

  Future<void> logout() {
    AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.data(null);
    _invalidateUserProviders();
    routerRefreshNotifier.value++;
    return AuthSessionCoordinator.serialize(() async {
      final rememberMe = await StorageService.getRememberMe();
      if (!ref.mounted) return;
      final result = await ref.read(authRepositoryProvider).logout();

      await result.fold((failure) async {
        await _clearLocalAuthState(clearSavedEmail: !rememberMe);
        ErrorReporter.report('logout', failure);
      }, (_) async => _clearLocalAuthState(clearSavedEmail: !rememberMe));
    });
  }

  Future<void> forceLogout() {
    AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.data(null);
    _invalidateUserProviders();
    routerRefreshNotifier.value++;
    return AuthSessionCoordinator.serialize(_clearLocalAuthState);
  }

  Future<void> expireSession() {
    AuthSessionCoordinator.beginAuthentication();
    ref.read(isInitialAuthLoadingProvider.notifier).set(false);
    state = const AsyncValue.data(null);
    _invalidateUserProviders();
    routerRefreshNotifier.value++;
    return AuthSessionCoordinator.serialize(
      () => _clearLocalAuthState(clearBiometric: false),
    );
  }

  Future<void> _clearBiometryIfAccountSwitch(
    UserEntity user, {
    required int attempt,
  }) => AuthSessionCoordinator.serialize(() async {
    if (!_isCurrentAuthAttempt(attempt)) return;
    final ownerId = await StorageService.getBiometricOwner();
    if (_isCurrentAuthAttempt(attempt) &&
        ownerId != null &&
        ownerId != user.id) {
      await BiometryService().clearState();
    }
  });

  Future<void> _clearLocalAuthState({
    bool clearBiometric = true,
    bool clearSavedEmail = false,
  }) async {
    HttpClient.suspendRefresh();
    state = const AsyncValue.data(null);
    try {
      await NotificationService().clearToken();
    } catch (error, stack) {
      ErrorReporter.report('push-token-revoke', error, stack);
    }
    if (clearBiometric) {
      try {
        await BiometryService().clearState();
      } catch (_) {}
    }
    try {
      await StorageService.clearTokens();
    } catch (_) {}
    if (clearSavedEmail) {
      try {
        await StorageService.clearEmail();
      } catch (_) {}
    }
    _invalidateUserProviders();
    state = const AsyncValue.data(null);
    routerRefreshNotifier.value++;
  }
}
