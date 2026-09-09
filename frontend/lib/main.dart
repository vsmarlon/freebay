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
import 'core/providers/theme_provider.dart';
import 'shared/config/app_config.dart';
import 'shared/services/http_client.dart';
import 'shared/services/error_reporter.dart';
import 'shared/services/notification_service.dart';
import 'core/router/app_link.dart';
import 'shared/services/storage_service.dart';
import 'shared/services/session_timeout.dart';
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
  NotificationService().onNotificationTapped = (data) {
    appRouter.go(AppLink.fromNotification(data));
  };
  unawaited(NotificationService().consumeLaunchNotification());

  ErrorWidget.builder = (d) => AppErrorWidget(details: d);
  runApp(const ProviderScope(child: FreeBayApp()));
}

class FreeBayApp extends ConsumerStatefulWidget {
  const FreeBayApp({super.key});

  @override
  ConsumerState<FreeBayApp> createState() => _FreeBayAppState();
}

class _FreeBayAppState extends ConsumerState<FreeBayApp> {
  late final SessionTimeout _sessionTimeout;
  bool _expiring = false;

  @override
  void initState() {
    super.initState();
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
    _sessionTimeout.dispose();
    super.dispose();
  }

  void _expireSession() {
    if (_expiring) return;
    _expiring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(authControllerProvider.notifier).forceLogout();
      await StorageService.clearLastActiveAt();
      appRouter.go('/login');
      final context = appRouter.configuration.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        await AppDialog.showError<void>(
          context: context,
          title: 'Sessão expirada',
          subtitle: 'Por segurança, entre novamente para continuar.',
          okText: 'Fazer login',
        );
      }
      _expiring = false;
    });
  }

  Future<void> _registerPushToken() async {
    final token = await NotificationService().getSavedToken();
    if (token == null || token.isEmpty) return;
    await ref.read(notificationRepositoryProvider).updateFcmToken(token);
  }

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
