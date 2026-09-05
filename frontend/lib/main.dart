import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/components/app_error_widget.dart';
import 'shared/config/app_config.dart';
import 'shared/services/http_client.dart';
import 'shared/services/notification_service.dart';
import 'shared/services/storage_service.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/data/entities/user_entity.dart';

void main() {
  runZonedGuarded(_bootstrap, (e, s) => debugPrint('[FATAL] $e\n$s'));
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[AppConfig] Info: No .env asset loaded from bundle ($e)');
  }
  await StorageService.init();
  if (!kIsWeb && AppConfig.stripePublishableKey.isNotEmpty) {
    try {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('[Stripe] Initialization error: $e');
    }
  }
  await Hive.initFlutter();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[Firebase] Initialization skipped or failed: $e');
  }
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('[NotificationService] Initialization error: $e');
  }
  ErrorWidget.builder = (d) => AppErrorWidget(details: d);
  runApp(const ProviderScope(child: FreeBayApp()));
}

class FreeBayApp extends ConsumerStatefulWidget {
  const FreeBayApp({super.key});

  @override
  ConsumerState<FreeBayApp> createState() => _FreeBayAppState();
}

class _FreeBayAppState extends ConsumerState<FreeBayApp> {
  @override
  void initState() {
    super.initState();
    HttpClient.onAuthLost = () {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authControllerProvider.notifier).forceLogout();
        appRouter.go('/login');
      });
    };
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
      builder: (context, child) => DarkModeInherited(
        isDarkMode: isDark,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
