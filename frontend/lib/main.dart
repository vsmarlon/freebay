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
import 'shared/services/session_timeout.dart';
import 'shared/services/payment_sdk_service.dart';
import 'shared/services/auth_session_coordinator.dart';
import 'shared/l10n/generated/app_localizations.dart';
import 'shared/l10n/app_locale_resolution.dart';
import 'shared/l10n/app_localizations_context.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/data/entities/user_entity.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    ErrorWidget.builder = (details) => AppErrorWidget(
      details: details,
      action: _canPopRouter() ? AppErrorAction.back : AppErrorAction.home,
      onRecover: _recoverFromError,
    );

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

Future<void> _recoverFromError() async {
  final navigatorContext = appRouter.configuration.navigatorKey.currentContext;
  if (navigatorContext?.mounted == true) {
    try {
      if (await appRouter.routerDelegate.popRoute()) return;
    } catch (error, stack) {
      ErrorReporter.report('error-navigation-recovery', error, stack);
    }
    runApp(ProviderScope(key: UniqueKey(), child: const FreeBayApp()));
  } else {
    await _bootstrap();
  }
  appRouter.go(AppRoutes.feed);
}

bool _canPopRouter() =>
    appRouter.configuration.navigatorKey.currentContext?.mounted == true &&
    appRouter.routerDelegate.currentConfiguration.matches.isNotEmpty &&
    appRouter.canPop();

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
  late final SessionTimeout _sessionTimeout;
  bool _expiring = false;
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
    _sessionTimeout = SessionTimeout(
      onExpired: _expireSession,
      isAuthenticated: () => ref.read(authControllerProvider).value != null,
    )..start();

    HttpClient.onAuthLost = _expireSession;

    ref.listenManual(authControllerProvider, (previous, next) {
      final user = next.value;
      final previousUser = previous?.value;
      if (previousUser != null && previousUser.id != user?.id) {
        unawaited(StorageService.clearUserCache(userId: previousUser.id));
      }
      if (user == null || previous?.value?.id == user.id) return;
      _sessionTimeout.touch();
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
    _sessionTimeout.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
      final biometricAvailable = await _biometricLoginAvailable();
      final context = appRouter.configuration.navigatorKey.currentContext;
      if (context == null || !context.mounted) {
        await ref.read(authControllerProvider.notifier).expireSession();
        return;
      }

      final dialog = AppDialog.showError<void>(
        context: context,
        title: l10n(context).authSessionExpired,
        subtitle: l10n(context).authSessionExpiredBody,
        okText: biometricAvailable
            ? l10n(context).authUseBiometrics
            : l10n(context).authLogin,
        onOk: () => _reauthenticateAfterExpiry(interrupted, biometricAvailable),
        dismissText: l10n(context).authContinueAsGuest,
        onDismiss: () => appRouter.go(AppRoutes.feed),
        barrierDismissible: false,
        preventBack: true,
      );

      await ref.read(authControllerProvider.notifier).expireSession();
      await StorageService.clearLastActiveAt();
      await dialog;
    } finally {
      _expiring = false;
    }
  }

  Future<bool> _biometricLoginAvailable() async {
    final service = ref.read(biometryServiceProvider);
    return await service.isAvailable() &&
        await service.isEnabled() &&
        await service.hasCredentials();
  }

  Future<void> _reauthenticateAfterExpiry(
    String interrupted,
    bool biometricAvailable,
  ) async {
    if (biometricAvailable &&
        await ref.read(authControllerProvider.notifier).loginWithBiometrics()) {
      appRouter.go(resolvePostAuthDestination(interrupted));
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
          final authToken = await StorageService.getToken();
          if (!mounted ||
              authToken == null ||
              ref.read(authControllerProvider).value?.id != userId) {
            return;
          }
          final result = await ref
              .read(notificationRepositoryProvider)
              .updateFcmToken(
                token,
                installationId: installationId,
                authToken: authToken,
              );
          result.fold(
            (failure) => ErrorReporter.report('push-token', failure),
            (_) {},
          );
        } catch (error, stack) {
          ErrorReporter.report('push-token', error, stack);
        }
      });

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<UserEntity?>>(authControllerProvider, (_, _) {
      routerRefreshNotifier.value++;
    });
    final themeMode = ref.watch(themeModeProvider);
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
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeListResolutionCallback: (locales, _) => resolveAppLocale(locales),
      scrollBehavior: const _FreeBayScrollBehavior(),
      builder: (context, child) => Listener(
        onPointerDown: (_) => _sessionTimeout.touch(),
        child: DarkModeInherited(
          isDarkMode: isDark,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _FreeBayScrollBehavior extends MaterialScrollBehavior {
  const _FreeBayScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
}
