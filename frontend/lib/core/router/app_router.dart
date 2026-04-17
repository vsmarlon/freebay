import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:freebay/features/auth/presentation/pages/splash_page.dart';
import 'package:freebay/features/auth/presentation/pages/login_page.dart';
import 'package:freebay/features/auth/presentation/pages/register_page.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/social/presentation/pages/post_details_page.dart';
import 'package:freebay/features/social/presentation/pages/post_search_page.dart';
import 'package:freebay/features/social/presentation/pages/create_post_page.dart';
import 'package:freebay/features/social/presentation/pages/comments_page.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_wrapper.dart';
import 'package:freebay/features/social/presentation/pages/create_story_page.dart';
import 'package:freebay/features/social/presentation/pages/my_stories_page.dart';
import 'package:freebay/features/social/presentation/pages/my_posts_page.dart';
import 'package:freebay/features/social/presentation/pages/liked_posts_page.dart';
import 'package:freebay/features/product/presentation/pages/product_list_page.dart';
import 'package:freebay/features/product/presentation/pages/explorar_page.dart';
import 'package:freebay/features/product/presentation/pages/product_detail_page.dart';
import 'package:freebay/features/product/presentation/pages/create_product_page.dart';
import 'package:freebay/features/product/presentation/pages/edit_product_page.dart';
import 'package:freebay/features/product/presentation/pages/my_products_page.dart';
import 'package:freebay/features/product/presentation/pages/cart_page.dart';
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/profile/presentation/pages/profile_page.dart';
import 'package:freebay/features/profile/presentation/pages/user_profile_page.dart';
import 'package:freebay/features/profile/presentation/pages/blocked_users_page.dart';
import 'package:freebay/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:freebay/features/profile/presentation/pages/followers_page.dart';
import 'package:freebay/features/profile/presentation/pages/following_page.dart';
import 'package:freebay/features/profile/presentation/pages/favorites_page.dart';
import 'package:freebay/features/profile/presentation/pages/saved_posts_page.dart';
import 'package:freebay/features/profile/presentation/pages/wishlist_page.dart';
import 'package:freebay/features/profile/presentation/pages/purchases_page.dart';
import 'package:freebay/features/profile/presentation/pages/payment_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/pages/new_chat_page.dart';
import 'package:freebay/features/notifications/presentation/pages/notifications_page.dart';
import 'package:freebay/features/reviews/presentation/pages/user_reviews_page.dart';
import 'package:freebay/features/reviews/presentation/pages/create_review_page.dart';
import 'package:freebay/features/cart/presentation/pages/cart_checkout_page.dart';
import 'package:freebay/features/orders/presentation/pages/order_detail_page.dart';
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
      path: '/posts/search',
      builder: (context, state) => const PostSearchPage(),
    ),
    GoRoute(
      path: '/products/create',
      builder: (context, state) => const CreateProductPage(),
    ),
    GoRoute(
      path: '/products/:id/edit',
      builder: (context, state) =>
          EditProductPage(productId: state.pathParameters['id']!),
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
            child: const ExplorarPage(),
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
          routes: [
            GoRoute(
              path: ':chatId',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return ChatConversationPage(
                  chatId: state.pathParameters['chatId']!,
                  oderName: extra?['oderName'] ?? 'Chat',
                  oderAvatarUrl: extra?['oderAvatarUrl'],
                  chatType: extra?['chatType'] ?? 'order',
                );
              },
            ),
            GoRoute(
              path: 'new',
              builder: (context, state) => const NewChatPage(),
            ),
          ],
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
      path: '/profile/blocked',
      builder: (context, state) => const BlockedUsersPage(),
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const NotificationsPage(),
      ),
    ),
    GoRoute(
      path: '/profile/posts',
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'] ?? 'me';
        return MyPostsPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/profile/stories',
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'] ?? 'me';
        return MyStoriesPage(userId: userId);
      },
    ),
    GoRoute(
      path: '/profile/products',
      builder: (context, state) => const MyProductsPage(),
    ),
    GoRoute(
      path: '/profile/liked',
      builder: (context, state) => const LikedPostsPage(),
    ),
    GoRoute(
      path: '/profile/favorites',
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: '/profile/saved',
      builder: (context, state) => const SavedPostsPage(),
    ),
    GoRoute(
      path: '/profile/wishlist',
      builder: (context, state) => const WishlistPage(),
    ),
    GoRoute(
      path: '/profile/purchases',
      builder: (context, state) => const PurchasesPage(),
    ),
    GoRoute(
      path: '/profile/payment',
      builder: (context, state) => const PaymentPage(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/profile/followers',
      builder: (context, state) =>
          FollowersPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
    ),
    GoRoute(
      path: '/profile/following',
      builder: (context, state) =>
          FollowingPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: '/checkout/cart',
      builder: (context, state) => const CartCheckoutPage(),
    ),
    GoRoute(
      path: '/orders/:orderId',
      builder: (context, state) =>
          OrderDetailPage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: '/user/:id/reviews',
      builder: (context, state) {
        final userName = state.uri.queryParameters['name'];
        return UserReviewsPage(
          userId: state.pathParameters['id']!,
          userName: userName,
        );
      },
    ),
    GoRoute(
      path: '/reviews/create',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CreateReviewPage(
          orderId: extra['orderId'] as String,
          reviewedId: extra['reviewedId'] as String,
          reviewedName: extra['reviewedName'] as String,
          reviewedAvatarUrl: extra['reviewedAvatarUrl'] as String?,
          reviewType: extra['reviewType'] as String,
        );
      },
    ),
    GoRoute(
      path: '/:path(.*)',
      redirect: (context, state) => '/login',
    ),
  ],
);
