import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:freebay/core/ui.dart';
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
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/error_reporter.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/product/presentation/pages/explorar_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';

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

final List<String> _guestBrowsableRoutes = [
  AppRoutes.feed,
  AppRoutes.explore,
  AppRoutes.products,
  AppRoutes.wallet,
  AppRoutes.chat,
  AppRoutes.profile,
  AppRoutes.postSearch,
  AppRoutes.peopleSearch,
];

final List<String> _guestBrowsablePrefixes = ['/products/', '/post/', '/user/'];

bool _isGuestBrowsable(String location) {
  if (_guestBrowsableRoutes.contains(location)) return true;
  return _guestBrowsablePrefixes.any(
    (prefix) =>
        location.startsWith(prefix) && location != AppRoutes.createProduct,
  );
}

final Set<String> _authScreenPaths = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.recoverPassword,
  AppRoutes.resetPassword,
  AppRoutes.onboarding,
  AppRoutes.completeProfile,
};

bool hasSeenWelcome(UserEntity user) {
  try {
    return StorageService.hasSeenWelcomeSetupSync(user.id);
  } catch (_) {
    return true;
  }
}

String resolvePostAuthDestination(String? from) {
  if (from == null || from.isEmpty) return AppRoutes.feed;
  final decoded = Uri.decodeComponent(from);
  if (!decoded.startsWith('/') || decoded.startsWith('//')) {
    return AppRoutes.feed;
  }
  final path = Uri.parse(decoded).path;
  if (_authScreenPaths.contains(path)) return AppRoutes.feed;
  return decoded;
}

String loginPathFrom(BuildContext context) {
  final location = GoRouterState.of(context).uri.toString();
  if (location.isEmpty || _authScreenPaths.contains(Uri.parse(location).path)) {
    return AppRoutes.login;
  }
  return '${AppRoutes.login}?from=${Uri.encodeComponent(location)}';
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: routerRefreshNotifier,
  errorBuilder: (context, state) {
    if (kDebugMode) {
      debugPrint('[GoRouter] Error navigating to ${state.uri}: ${state.error}');
    }
    final canPop =
        appRouter.configuration.navigatorKey.currentContext?.mounted == true &&
        appRouter.routerDelegate.currentConfiguration.matches.isNotEmpty &&
        appRouter.canPop();
    return AppErrorWidget(
      details: FlutterErrorDetails(
        exception: state.error ?? StateError('Route navigation failed'),
      ),
      action: canPop ? AppErrorAction.back : AppErrorAction.home,
      onRecover: () async {
        final navigatorContext =
            appRouter.configuration.navigatorKey.currentContext;
        try {
          if (navigatorContext?.mounted == true &&
              await appRouter.routerDelegate.popRoute()) {
            return;
          }
        } catch (error, stack) {
          ErrorReporter.report('route-error-recovery', error, stack);
        }
        appRouter.go(AppRoutes.feed);
      },
    );
  },
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final isInitialLoading = container.read(isInitialAuthLoadingProvider);

    if (isInitialLoading) {
      if (state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.splash;
      }
      return null;
    }

    final authState = container.read(authControllerProvider);
    final user = authState.value;

    if (user == null) {
      if (state.matchedLocation == AppRoutes.splash) {
        final hasSeen = container.read(hasSeenOnboardingProvider);
        return hasSeen ? AppRoutes.login : AppRoutes.onboarding;
      }
      if (state.matchedLocation == AppRoutes.completeProfile) {
        return AppRoutes.login;
      }
      final isPublic =
          _publicRoutes.any((p) => state.matchedLocation == p) ||
          _isGuestBrowsable(state.matchedLocation);
      if (!isPublic) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.login}?from=$from';
      }
      updateCurrentLocation(state.matchedLocation);
      return null;
    }

    final isAuthScreen =
        state.matchedLocation == AppRoutes.splash ||
        state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register ||
        state.matchedLocation == AppRoutes.recoverPassword ||
        state.matchedLocation == AppRoutes.resetPassword ||
        state.matchedLocation == AppRoutes.onboarding;

    final needsProfile = user.username == null;
    if (needsProfile) {
      return state.matchedLocation == AppRoutes.completeProfile
          ? null
          : AppRoutes.completeProfile;
    }
    if (state.matchedLocation == AppRoutes.completeProfile) {
      return AppRoutes.feed;
    }

    final welcomeDone = hasSeenWelcome(user);
    if (state.matchedLocation == AppRoutes.welcome) {
      if (welcomeDone) {
        return resolvePostAuthDestination(state.uri.queryParameters['from']);
      }
      return null;
    }
    if (!welcomeDone) {
      return AppRoutes.welcome;
    }

    if (isAuthScreen) {
      return resolvePostAuthDestination(state.uri.queryParameters['from']);
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
    StatefulShellRoute(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) => navigationShell,
      navigatorContainerBuilder: (context, navigationShell, children) =>
          AppShell(navigationShell: navigationShell, branches: children),
      branches: [
        appShellBranch(AppRoutes.feed, (context, state) => const FeedPage()),
        appShellBranch(
          AppRoutes.explore,
          (context, state) => const ExplorarPage(),
          additionalRoutes: [
            appCupertinoRoute(
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
