import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freebay/features/auth/presentation/pages/splash_page.dart';
import 'package:freebay/features/auth/presentation/pages/login_page.dart';
import 'package:freebay/features/auth/presentation/pages/register_page.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/social/presentation/pages/post_details_page.dart';
import 'package:freebay/features/social/presentation/pages/create_post_page.dart';
import 'package:freebay/features/social/presentation/pages/comments_page.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_wrapper.dart';
import 'package:freebay/features/social/presentation/pages/create_story_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/features/product/presentation/pages/product_detail_page.dart';
import 'package:freebay/features/product/presentation/pages/create_product_page.dart';
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';
import 'package:freebay/features/profile/presentation/pages/user_profile_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/core/components/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildPageWithSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.05, 0),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const RegisterPage(),
      ),
    ),
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostPage(),
    ),
    GoRoute(
      path: '/post/:id',
      builder: (context, state) =>
          PostDetailsPage(postId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'comments',
          builder: (context, state) =>
              CommentsPage(postId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: '/products/create',
      builder: (context, state) => const CreateProductPage(),
    ),
    GoRoute(
      path: '/products/:id',
      builder: (context, state) =>
          ProductDetailPage(productId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/story',
      builder: (context, state) => StoryViewerWrapper(
        indexParam: state.uri.queryParameters['index'],
      ),
    ),
    GoRoute(
      path: '/create-story',
      builder: (context, state) => const CreateStoryPage(),
    ),
    GoRoute(
      path: '/user/:id',
      builder: (context, state) =>
          UserProfilePage(userId: state.pathParameters['id']!),
    ),
    // Shell routes (with bottom nav)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/feed',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const FeedPage(),
          ),
        ),
        GoRoute(
          path: '/explore',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const ProductListPage(),
          ),
        ),
        GoRoute(
          path: '/products',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const ProductListPage(),
          ),
        ),
        GoRoute(
          path: '/wallet',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const WalletPage(),
          ),
        ),
        GoRoute(
          path: '/chat',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const ChatListPage(),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const ProfilePage(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/:path(.*)',
      redirect: (context, state) => '/login',
    ),
  ],
);
