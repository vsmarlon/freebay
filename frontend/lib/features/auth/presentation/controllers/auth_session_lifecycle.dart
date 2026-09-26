part of 'auth_controller.dart';

mixin AuthSessionLifecycle on Notifier<AsyncValue<UserEntity?>> {
  Future<void> _initAuth() async {
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    ref.read(isInitialAuthLoadingProvider.notifier).set(true);

    try {
      final hasSeenOnboarding = StorageService.hasSeenOnboardingSync();
      if (!ref.mounted) return;
      ref.read(hasSeenOnboardingProvider.notifier).set(hasSeenOnboarding);

      final rememberMe = await StorageService.getRememberMe();
      if (!ref.mounted) return;
      if (!rememberMe) {
        await StorageService.clearTokens();
        if (!ref.mounted) return;
        state = const AsyncValue.data(null);
        return;
      }

      final token = await StorageService.getToken();
      if (!ref.mounted) return;
      if (token == null) {
        await _tryBiometricLogin();
        return;
      }

      final result = await ref.read(getCurrentUserUsecaseProvider)();
      if (!ref.mounted) return;
      await result.fold(
        (failure) async {
          await StorageService.clearTokens();
          if (!ref.mounted) return;
          state = const AsyncValue.data(null);
        },
        (user) async {
          if (!ref.mounted) return;
          await AuthSessionCoordinator.establishSession();
          state = AsyncValue.data(user);
        },
      );
    } catch (_) {
      await StorageService.clearTokens();
      if (!ref.mounted) return;
      state = const AsyncValue.data(null);
    } finally {
      if (ref.mounted) {
        ref.read(isInitialAuthLoadingProvider.notifier).set(false);
        routerRefreshNotifier.value++;
      }
    }
  }

  Future<void> _tryBiometricLogin() async {
    final result = await ref.read(biometricLoginUsecaseProvider)();
    if (!ref.mounted) return;
    result.fold(
      (failure) => state = const AsyncValue.data(null),
      (user) => state = AsyncValue.data(user),
    );
  }

  void _invalidateUserProviders() {
    ref.read(walletProvider.notifier).reset();
    ref.read(walletHistoryProvider.notifier).reset();
    ref.read(connectStatusProvider.notifier).reset();
    ref.invalidate(walletProvider);
    ref.invalidate(walletHistoryProvider);
    ref.invalidate(connectStatusProvider);
    ref.invalidate(cartProvider);
    ref.invalidate(disputeListProvider);
    ref.invalidate(purchasesListProvider);
    ref.invalidate(salesListProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(chatsProvider);
    ref.invalidate(liveChatListProvider);
    ref.invalidate(archivedChatListProvider);
  }

  Future<void> logout() async {
    HttpClient.suspendRefresh();
    final rememberMe = await StorageService.getRememberMe();
    if (!ref.mounted) return;
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).logout();

    await result.fold((failure) async {
      await _clearLocalAuthState(clearSavedEmail: !rememberMe);
      ErrorReporter.report('logout', failure);
    }, (_) async => _clearLocalAuthState(clearSavedEmail: !rememberMe));
  }

  Future<void> forceLogout() async => _clearLocalAuthState();

  Future<void> expireSession() async {
    HttpClient.suspendRefresh();
    await _clearLocalAuthState(clearBiometric: false);
  }

  Future<void> _clearBiometryIfAccountSwitch(UserEntity user) async {
    final ownerId = await StorageService.getBiometricOwner();
    if (ownerId != null && ownerId != user.id) {
      await BiometryService().clearState();
    }
  }

  Future<void> _clearLocalAuthState({
    bool clearBiometric = true,
    bool clearSavedEmail = false,
  }) async {
    HttpClient.suspendRefresh();
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
