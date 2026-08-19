import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freebay/core/router/navigation_tracker.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/core/router/routes/auth_routes.dart';
import 'package:freebay/core/router/routes/social_routes.dart';
import 'package:freebay/core/router/routes/product_routes.dart';
import 'package:freebay/core/router/routes/chat_routes.dart';
import 'package:freebay/core/router/routes/profile_routes.dart';
import 'package:freebay/core/router/routes/order_routes.dart';
import 'package:freebay/core/router/routes/support_routes.dart';

import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/product/presentation/pages/explorar_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';
import 'package:freebay/core/components/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerRefreshNotifier = ValueNotifier<int>(0);

final List<String> _publicRoutes = [
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.recoverPassword,
  AppRoutes.resetPassword,
  AppRoutes.onboarding,
];

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final isInitialLoading = container.read(isInitialAuthLoadingProvider);

    // Keep user on splash strictly during cold-boot startup check
    if (isInitialLoading) {
      if (state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.splash;
      }
      return null;
    }

    final authState = container.read(authControllerProvider);
    final user = authState.value;

    // Unauthenticated user handling
    if (user == null) {
      if (state.matchedLocation == AppRoutes.splash) {
        final hasSeen = container.read(hasSeenOnboardingProvider);
        return hasSeen ? AppRoutes.login : AppRoutes.onboarding;
      }
      final isPublic = _publicRoutes.any((p) => state.matchedLocation == p);
      if (!isPublic) {
        return AppRoutes.login;
      }
      updateCurrentLocation(state.matchedLocation);
      return null;
    }

    // Authenticated user handling
    final isAuthScreen =
        state.matchedLocation == AppRoutes.splash ||
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.recoverPassword ||
        state.matchedLocation == AppRoutes.resetPassword ||
        state.matchedLocation == AppRoutes.onboarding;

    // Google OAuth users without username need to complete profile
    final needsProfile = user.username == null;
    if (needsProfile && state.matchedLocation != AppRoutes.completeProfile) {
      return AppRoutes.completeProfile;
    }
    if (!needsProfile && state.matchedLocation == AppRoutes.completeProfile) {
      return AppRoutes.feed;
    }

    if (isAuthScreen) {
      return AppRoutes.feed;
    }

    updateCurrentLocation(state.matchedLocation);
    return null;
  },
  routes: [
    ...authRoutes,
    ...socialRoutes,
    ...productRoutes,
    ...chatRoutes,
    ...profileRoutes,
    ...orderRoutes,
    ...supportRoutes,

    // Shell routes (with bottom nav)
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        appShellBranch(AppRoutes.feed, (context, state) => const FeedPage()),
        appShellBranch(
          AppRoutes.explore,
          (context, state) => const ExplorarPage(),
          additionalRoutes: [
            appSlideRoute(
              AppRoutes.products,
              (context, state) => const ProductListPage(),
            ),
          ],
        ),
        appShellBranch(
          AppRoutes.wallet,
          (context, state) => const WalletPage(),
        ),
        appShellBranch(
          AppRoutes.chat,
          (context, state) => const ChatListPage(),
        ),
        appShellBranch(
          AppRoutes.profile,
          (context, state) => const ProfilePage(),
        ),
      ],
    ),

    GoRoute(
      path: AppRoutes.wildCard,
      redirect: (context, state) => AppRoutes.login,
    ),
  ],
);
