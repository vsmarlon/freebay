import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'shared/config/app_config.dart';
import 'shared/services/http_client.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[CONFIG] Firebase initialization skipped: $e');
  }

  debugPrint('[CONFIG] API base URL: ${AppConfig.apiBaseUrl}');
  if (!AppConfig.isUsingApiOverride) {
    debugPrint(
      '[CONFIG] Using platform default API host. For physical devices, run with --dart-define=API_BASE_URL=http://YOUR_LAN_IP:3000',
    );
  }

  final notificationService = NotificationService();
  await notificationService.initialize();

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
    HttpClient.onAuthLost = _handleAuthLost;
  }

  void _handleAuthLost() {
    // Navigate to login when auth is lost (token expired + refresh failed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appRouter.go('/login');
    });
  }

  bool _computeIsDarkMode(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return mode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = _computeIsDarkMode(themeMode);

    return DarkModeInherited(
      isDarkMode: isDark,
      child: MaterialApp.router(
        title: 'FreeBay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        routerConfig: appRouter,
      ),
    );
  }
}
