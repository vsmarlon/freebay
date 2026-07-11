import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'navigation_tracker.dart';
import 'app_routes.dart';

import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/presentation/pages/splash_page.dart';
import 'package:freebay/features/auth/presentation/pages/login_page.dart';
import 'package:freebay/features/auth/presentation/pages/register_page.dart';
import 'package:freebay/features/auth/presentation/pages/password_recovery_page.dart';
import 'package:freebay/features/auth/presentation/pages/reset_password_page.dart';
import 'package:freebay/features/onboarding/presentation/pages/onboarding_page.dart';
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
import 'package:freebay/features/profile/presentation/pages/purchases_page.dart';
import 'package:freebay/features/payments/presentation/pages/payment_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_list_page.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/pages/new_chat_page.dart';
import 'package:freebay/features/chat/presentation/pages/archived_chats_page.dart';
import 'package:freebay/features/help/presentation/pages/faq_page.dart';
import 'package:freebay/features/notifications/presentation/pages/notifications_page.dart';
import 'package:freebay/features/reviews/presentation/pages/user_reviews_page.dart';
import 'package:freebay/features/reviews/presentation/pages/create_review_page.dart';
import 'package:freebay/features/cart/presentation/pages/cart_checkout_page.dart';
import 'package:freebay/features/orders/presentation/pages/order_detail_page.dart';
import 'package:freebay/features/dispute/presentation/pages/dispute_list_page.dart';
import 'package:freebay/features/dispute/presentation/pages/dispute_detail_page.dart';
import 'package:freebay/features/dispute/presentation/pages/create_dispute_page.dart';
import 'package:freebay/core/components/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage<void> _buildPageWithSlideTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.linear,
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

final routerRefreshNotifier = ValueNotifier<int>(0);

final List<String> _publicRoutes = [
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.recoverPassword,
  AppRoutes.resetPassword,
];

final List<String> _guestRestrictedRoutes = [
  AppRoutes.wallet,
  AppRoutes.chat,
  AppRoutes.profile,
  AppRoutes.checkout,
  AppRoutes.orders,
  AppRoutes.disputes,
  AppRoutes.reviews,
];

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: routerRefreshNotifier,
  redirect: (context, state) {
    final container = ProviderScope.containerOf(context, listen: false);
    final authState = container.read(authControllerProvider);

    // Keep user on splash during initial loading state
    if (authState.isLoading) {
      if (state.matchedLocation != AppRoutes.splash) {
        return AppRoutes.splash;
      }
      return null;
    }

    final user = authState.valueOrNull;

    // Unauthenticated user handling
    if (user == null) {
      if (state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.login;
      }
      final isPublic = _publicRoutes.any((p) => state.matchedLocation == p);
      if (!isPublic) {
        return AppRoutes.login;
      }
      updateCurrentLocation(state.matchedLocation);
      return null;
    }

    // Authenticated user handling
    if (user.isGuest) {
      // Guests navigating to restricted routes go to /login
      final isRestricted = _guestRestrictedRoutes.any(
        (p) =>
            state.matchedLocation == p ||
            state.matchedLocation.startsWith('$p/'),
      );
      if (isRestricted) {
        return AppRoutes.login;
      }
      // Guest landing on splash goes to /feed
      if (state.matchedLocation == AppRoutes.splash) {
        return AppRoutes.feed;
      }
    } else {
      // Non-guest authenticated users are redirected away from splash/login/register to /feed
      final isAuthScreen =
          state.matchedLocation == AppRoutes.splash ||
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      if (isAuthScreen) {
        return AppRoutes.feed;
      }
    }

    // Onboarding check for non-guest users
    if (state.matchedLocation != AppRoutes.onboarding &&
        !user.isGuest &&
        !container.read(hasSeenOnboardingProvider)) {
      return AppRoutes.onboarding;
    }

    updateCurrentLocation(state.matchedLocation);
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const LoginPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const RegisterPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.recoverPassword,
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: const PasswordRecoveryPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      pageBuilder: (context, state) => _buildPageWithSlideTransition(
        context: context,
        state: state,
        child: ResetPasswordPage(
          token: state.uri.queryParameters['token'] ?? '',
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.createPost,
      builder: (context, state) => const CreatePostPage(),
    ),
    GoRoute(
      path: AppRoutes.postDetails,
      builder: (context, state) =>
          PostDetailsPage(postId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: AppRoutes.comments,
          builder: (context, state) =>
              CommentsPage(postId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.postSearch,
      builder: (context, state) => const PostSearchPage(),
    ),
    GoRoute(
      path: AppRoutes.createProduct,
      builder: (context, state) => const CreateProductPage(),
    ),
    GoRoute(
      path: AppRoutes.productDetail,
      builder: (context, state) =>
          ProductDetailPage(productId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: AppRoutes.editProduct,
          builder: (context, state) =>
              EditProductPage(productId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.story,
      builder: (context, state) =>
          StoryViewerWrapper(indexParam: state.uri.queryParameters['index']),
    ),
    GoRoute(
      path: AppRoutes.createStory,
      builder: (context, state) => const CreateStoryPage(),
    ),
    GoRoute(
      path: AppRoutes.userProfile,
      builder: (context, state) =>
          UserProfilePage(userId: state.pathParameters['id']!),
    ),
    // Shell routes (with bottom nav)
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.feed,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const FeedPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.explore,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const ExplorarPage(),
              ),
            ),
            GoRoute(
              path: AppRoutes.products,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const ProductListPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.wallet,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const WalletPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.chat,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const ChatListPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) => _buildPageWithSlideTransition(
                context: context,
                state: state,
                child: const ProfilePage(),
              ),
            ),
          ],
        ),
      ],
    ),
    // Chat detail routes live at top level (outside the shell) so they render
    // full-screen over the bottom nav. `/chat/new` is declared before
    // `/chat/:chatId` so "new" is not captured as a chat id.
    GoRoute(
      path: AppRoutes.chatNew,
      builder: (context, state) => const NewChatPage(),
    ),
    GoRoute(
      path: AppRoutes.chatArchived,
      builder: (context, state) => const ArchivedChatsPage(),
    ),
    GoRoute(
      path: AppRoutes.chatConversation,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ChatConversationPage(
          chatId: state.pathParameters['chatId']!,
          orderName: extra?['orderName'] ?? 'Chat',
          orderAvatarUrl: extra?['orderAvatarUrl'],
          chatType: extra?['chatType'] ?? 'order',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.profileBlocked,
      builder: (context, state) => const BlockedUsersPage(),
    ),
    GoRoute(path: AppRoutes.faq, builder: (context, state) => const FaqPage()),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: AppRoutes.profilePosts,
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'] ?? 'me';
        return MyPostsPage(userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.profileStories,
      builder: (context, state) {
        final userId = state.uri.queryParameters['userId'] ?? 'me';
        return MyStoriesPage(userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.profileProducts,
      builder: (context, state) => const MyProductsPage(),
    ),
    GoRoute(
      path: AppRoutes.profileLiked,
      builder: (context, state) => const LikedPostsPage(),
    ),
    GoRoute(
      path: AppRoutes.profileFavorites,
      builder: (context, state) => const FavoritesPage(),
    ),
    GoRoute(
      path: AppRoutes.profileSaved,
      builder: (context, state) => const SavedPostsPage(),
    ),
    GoRoute(
      path: AppRoutes.profilePurchases,
      builder: (context, state) => const PurchasesPage(),
    ),
    GoRoute(
      path: AppRoutes.profilePayment,
      builder: (context, state) => const PaymentPage(),
    ),
    GoRoute(
      path: AppRoutes.profileEdit,
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.profileFollowers,
      builder: (context, state) =>
          FollowersPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
    ),
    GoRoute(
      path: AppRoutes.profileFollowing,
      builder: (context, state) =>
          FollowingPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
    ),
    GoRoute(
      path: AppRoutes.cart,
      builder: (context, state) => const CartPage(),
    ),
    GoRoute(
      path: AppRoutes.checkoutCart,
      builder: (context, state) => const CartCheckoutPage(),
    ),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (context, state) =>
          OrderDetailPage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: AppRoutes.userReviews,
      builder: (context, state) {
        final userName = state.uri.queryParameters['name'];
        return UserReviewsPage(
          userId: state.pathParameters['id']!,
          userName: userName,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.createReview,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null) {
          return const Scaffold(
            body: Center(child: Text('Error: Missing review details.')),
          );
        }
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
      path: AppRoutes.disputes,
      builder: (context, state) => const DisputeListPage(),
    ),
    GoRoute(
      path: AppRoutes.createDispute,
      builder: (context, state) =>
          CreateDisputePage(orderId: state.pathParameters['orderId']!),
    ),
    GoRoute(
      path: AppRoutes.disputeDetail,
      builder: (context, state) =>
          DisputeDetailPage(disputeId: state.pathParameters['disputeId']!),
    ),
    GoRoute(
      path: AppRoutes.wildCard,
      redirect: (context, state) => AppRoutes.login,
    ),
  ],
);
