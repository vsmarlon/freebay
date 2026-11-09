import 'package:freebay/core/ui.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/providers/theme_provider.dart';
import 'shared/services/http_client.dart';
import 'shared/services/error_reporter.dart';
import 'shared/services/notification_service.dart';
import 'core/router/app_link.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/payment_sdk_service.dart';
import 'shared/services/auth_session_coordinator.dart';
import 'shared/l10n/generated/app_localizations.dart';
import 'shared/l10n/app_locale_resolution.dart';
import 'shared/l10n/app_localizations_context.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/widgets/session_lock_gate.dart';
import 'features/auth/data/entities/user_entity.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';
import 'shared/providers/app_locale_preference_provider.dart';
import 'shared/providers/session_lock_preference_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (_) => const SizedBox.shrink();

    FlutterError.onError = (details) {
      if (!ErrorReporter.isEnabled) {
        ErrorReporter.report('flutter', details.exception, details.stack);
      }
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!ErrorReporter.isEnabled) {
        ErrorReporter.report('platform', error, stack);
      }
      return true;
    };

    try {
      await ErrorReporter.initialize();
    } catch (error, stack) {
      ErrorReporter.report('sentry-init', error, stack);
    }
    try {
      await _bootstrap();
    } catch (error, stack) {
      ErrorReporter.report('bootstrap', error, stack);
      _showStartupFailure(error, stack);
    }
  }, (e, s) => ErrorReporter.report('uncaught', e, s));
}

Future<void> _bootstrap() async {
  await Future.wait([
    StorageService.init(),
    Hive.initFlutter().catchError((Object error, StackTrace stack) {
      ErrorReporter.report('hive-init', error, stack);
    }),
  ]);
  StorageService.enableCacheStore();
  runApp(const ProviderScope(child: FreeBayApp()));
}

void _showStartupFailure(Object error, StackTrace stack) {
  runApp(
    MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      home: AppErrorWidget(
        details: FlutterErrorDetails(exception: error, stack: stack),
        onRecover: _bootstrap,
      ),
    ),
  );
}

Future<void> _initializeDeferredServices() async {
  await Future.wait([PaymentSdkService.ensureReady(), _initializeFirebase()]);
  try {
    await NotificationService().initialize();
    await NotificationService().consumeLaunchNotification();
  } catch (e, s) {
    ErrorReporter.report('notifications-init', e, s);
  }
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (error, stack) {
    ErrorReporter.report('firebase-init', error, stack);
  }
}

class FreeBayApp extends ConsumerStatefulWidget {
  const FreeBayApp({super.key});

  @override
  ConsumerState<FreeBayApp> createState() => _FreeBayAppState();
}

class _FreeBayAppState extends ConsumerState<FreeBayApp>
    with WidgetsBindingObserver {
  bool _expiring = false;
  bool _externalActivity = false;
  String? _pendingNotificationPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().onTokenChanged = _registerPushToken;
    NotificationService().onNotificationTapped = _openNotification;
    NotificationService().shouldShowNotification = (data) {
      final conversationId = data['conversationId'];
      return data['type'] != 'MESSAGE' ||
          conversationId is! String ||
          appRouter.routeInformationProvider.value.uri.path !=
              AppRoutes.chatPath(conversationId);
    };
    NotificationService().onNotificationReceived = (_, _) {
      if (!mounted || ref.read(authControllerProvider).value == null) return;
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
    };
    ref.listenManual(isInitialAuthLoadingProvider, (_, loading) {
      final pending = _pendingNotificationPath;
      if (!loading && pending != null) {
        _pendingNotificationPath = null;
        appRouter.go(pending);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initializeDeferredServices());
    });
    HttpClient.onAuthLost = _expireSession;

    ref.listenManual(authControllerProvider, (previous, next) {
      final user = next.value;
      final previousUser = previous?.value;
      if (previousUser != null && previousUser.id != user?.id) {
        unawaited(StorageService.clearUserCache(userId: previousUser.id));
      }
      if (user == null || previous?.value?.id == user.id) return;
      unawaited(_registerPushToken());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService().onTokenChanged = null;
    NotificationService().onNotificationTapped = null;
    NotificationService().onNotificationReceived = null;
    NotificationService().shouldShowNotification = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final externalActivity =
        state == AppLifecycleState.paused || state == AppLifecycleState.hidden;
    if (_externalActivity != externalActivity && mounted) {
      setState(() => _externalActivity = externalActivity);
    }
    if (state == AppLifecycleState.resumed) unawaited(_registerPushToken());
  }

  void _openNotification(Map<String, dynamic> data) {
    if (!mounted) return;
    final path = AppLink.fromNotification(data);
    if (ref.read(isInitialAuthLoadingProvider)) {
      _pendingNotificationPath = path;
    } else {
      appRouter.go(path);
    }
  }

  void _expireSession() {
    HttpClient.suspendRefresh();
    if (_expiring) return;
    _expiring = true;
    unawaited(_showExpiredSession());
  }

  Future<void> _showExpiredSession() async {
    try {
      await WidgetsBinding.instance.endOfFrame;
      final interrupted = appRouter.routeInformationProvider.value.uri
          .toString();
      final expired = ref.read(authControllerProvider.notifier).expireSession();
      final context = appRouter.configuration.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        await expired;
        return;
      }

      await AppDialog.showError<void>(
        context: context,
        title: l10n(context).authSessionExpired,
        subtitle: l10n(context).authSessionExpiredBody,
        okText: l10n(context).authLogin,
        onOk: () async {
          await expired;
          await _reauthenticateAfterExpiry(interrupted);
        },
        barrierDismissible: false,
        preventBack: true,
      );
      await expired;
    } finally {
      _expiring = false;
    }
  }

  /// The server refresh already failed, so the stored pair is dead: a biometric
  /// login is the only silent recovery left.
  Future<void> _reauthenticateAfterExpiry(String interrupted) async {
    final biometry = ref.read(biometryServiceProvider);
    final biometricLoginAvailable =
        await biometry.isEnabled() &&
        await biometry.isAvailable() &&
        await biometry.hasCredentials();
    if (biometricLoginAvailable &&
        await ref.read(authControllerProvider.notifier).loginWithBiometrics()) {
      navigatePostAuthDestination(interrupted);
      return;
    }
    final destination = resolvePostAuthDestination(interrupted);
    appRouter.go('${AppRoutes.login}?from=${Uri.encodeComponent(destination)}');
  }

  Future<void> _registerPushToken([String? _]) =>
      AuthSessionCoordinator.serialize(() async {
        if (!mounted) return;
        final userId = ref.read(authControllerProvider).value?.id;
        if (userId == null) return;
        try {
          final token = await NotificationService().getToken();
          if (token == null || token.isEmpty) return;
          final installationId = await StorageService.getPushInstallationId();
          if (!mounted ||
              ref.read(authControllerProvider).value?.id != userId) {
            return;
          }
          final result = await ref
              .read(notificationRepositoryProvider)
              .updateFcmToken(token, installationId: installationId);
          result.fold(
            (failure) => ErrorReporter.report('push-token', failure),
            (_) {},
          );
        } catch (error, stack) {
          ErrorReporter.report('push-token', error, stack);
        }
      });

  /// A conta lembra que o usuário quer biometria (`biometryLoginEnabled` do
  /// servidor); em um device que ainda não tem a chave local, oferecemos a
  /// ativação uma única vez. O flag `biometry_prompted` (local) guarda a
  /// decisão — aceite ou recusada — até uma troca de conta limpar o estado.
  Future<void> _maybeOfferBiometryEnrollment(UserEntity user) async {
    final biometry = ref.read(biometryServiceProvider);
    if (!user.biometryLoginEnabled) return;
    if (await biometry.isEnabled()) return;
    if (!await biometry.isAvailable()) return;
    if (await biometry.hasPrompted()) return;
    final context = appRouter.configuration.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final strings = l10n(context);
    await AppDialog.show<void>(
      context: context,
      icon: Icons.fingerprint,
      title: strings.authPermissionBiometry,
      subtitle: strings.onboardingBiometryBody,
      dismissText: strings.commonCancel,
      okText: strings.authUseBiometrics,
      onOk: () async {
        final enrolled = await ref
            .read(authControllerProvider.notifier)
            .enrollBiometrics(expectedUserId: user.id);
        if (enrolled || !context.mounted) return;
        AppSnackbar.error(context, strings.profileBiometryUpdateFailed);
      },
      onDismiss: () => biometry.setHasPrompted(true),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (
      previous,
      next,
    ) {
      routerRefreshNotifier.value++;
      final user = next.value;
      final previousId = previous?.value?.id;
      if (user != null && user.id != previousId) {
        unawaited(_maybeOfferBiometryEnrollment(user));
      }
    });
    final themeMode = ref.watch(themeModeProvider);
    final localePreference = ref.watch(appLocalePreferenceProvider);
    final lockMinutes = ref.watch(sessionLockPreferenceProvider);
    final accountId = ref.watch(authControllerProvider).value?.id;
    final isDark = themeMode == ThemeMode.system
        ? WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark
        : themeMode == ThemeMode.dark;

    return MaterialApp.router(
      title: 'FreeBay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: switch (localePreference) {
        'pt_BR' => const Locale('pt', 'BR'),
        'en' => const Locale('en'),
        _ => null,
      },
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      scrollBehavior: const _FreeBayScrollBehavior(),
      builder: (context, child) {
        final location = appRouter.routeInformationProvider.value.uri;
        final isPublicRoute = const {
          AppRoutes.splash,
          AppRoutes.login,
          AppRoutes.register,
          AppRoutes.recoverPassword,
          AppRoutes.resetPassword,
          AppRoutes.onboarding,
          AppRoutes.welcome,
          AppRoutes.completeProfile,
        }.contains(location.path);
        return DarkModeInherited(
          isDarkMode: isDark,
          child: SessionLockGate(
            accountId: accountId,
            lockAfter: lockMinutes == 0 ? null : Duration(minutes: lockMinutes),
            isPublicRoute: isPublicRoute,
            isExternalActivity: _externalActivity,
            onReauthenticate: (id) => ref
                .read(authControllerProvider.notifier)
                .reauthenticateSessionWithBiometrics(id),
            onUsePassword: () {
              final interrupted = location.toString();
              final destination = resolvePostAuthDestination(interrupted);
              unawaited(
                ref.read(authControllerProvider.notifier).expireSession().then((
                  _,
                ) {
                  if (!mounted) return;
                  appRouter.go(
                    '${AppRoutes.login}?from=${Uri.encodeComponent(destination)}',
                  );
                }),
              );
            },
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}

class _FreeBayScrollBehavior extends MaterialScrollBehavior {
  const _FreeBayScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
