import 'package:freebay/core/ui.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/providers/theme_provider.dart';
import 'shared/config/app_config.dart';
import 'shared/services/http_client.dart';
import 'shared/services/error_reporter.dart';
import 'shared/services/notification_service.dart';
import 'core/router/app_link.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/session_timeout.dart';
import 'shared/services/auth_session_coordinator.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/data/entities/user_entity.dart';
import 'features/notifications/presentation/providers/notifications_provider.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      ErrorReporter.report('flutter', details.exception, details.stack);
      if (kDebugMode) FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorReporter.report('platform', error, stack);
      return true;
    };

    try {
      await dotenv.load();
    } catch (e) {
      debugPrint('[AppConfig] Info: No .env asset loaded from bundle ($e)');
    }
    await ErrorReporter.run(_bootstrap);
  }, (e, s) => ErrorReporter.report('uncaught', e, s));
}

Future<void> _bootstrap() async {
  await StorageService.init();
  if (!kIsWeb && AppConfig.stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e, s) {
      ErrorReporter.report('stripe-init', e, s);
    }
  }
  await Hive.initFlutter();
  try {
    await Firebase.initializeApp();
  } catch (e, s) {
    ErrorReporter.report('firebase-init', e, s);
  }
  try {
    await NotificationService().initialize();
  } catch (e, s) {
    ErrorReporter.report('notifications-init', e, s);
  }
  ErrorWidget.builder = (d) => AppErrorWidget(details: d);
  runApp(const ProviderScope(child: FreeBayApp()));
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
      unawaited(NotificationService().consumeLaunchNotification());
    });
    _sessionTimeout = SessionTimeout(
      onExpired: _expireSession,
      isAuthenticated: () => ref.read(authControllerProvider).value != null,
    )..start();

    HttpClient.onAuthLost = _expireSession;

    ref.listenManual(authControllerProvider, (previous, next) {
      final user = next.value;
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
        title: 'Sessão expirada',
        subtitle: 'Por segurança, entre novamente para continuar.',
        okText: biometricAvailable ? 'Usar biometria' : 'Fazer login',
        onOk: () => _reauthenticateAfterExpiry(interrupted, biometricAvailable),
        dismissText: 'Continuar como convidado',
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
