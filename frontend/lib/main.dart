import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'shared/services/http_client.dart';

void main() {
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FreeBay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
