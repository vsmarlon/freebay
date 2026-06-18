import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'shared/config/app_config.dart';
import 'shared/services/http_client.dart';
import 'shared/services/notification_service.dart';
import 'core/components/spacing.dart';
import 'dart:async';

void main() {
  runZonedGuarded(
    () async {
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

      ErrorWidget.builder = (details) {
        return Material(
          color: AppColors.surfaceContainerLowest,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Color(0xFF8A1083)),
                  Spacing.vMd,
                  Text(
                    'Algo deu errado',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Spacing.vSm,
                  Text(
                    details.exception.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        );
      };

      runApp(const ProviderScope(child: FreeBayApp()));
    },
    (error, stack) {
      debugPrint('[FATAL] Uncaught error: $error\n$stack');
    },
  );
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
