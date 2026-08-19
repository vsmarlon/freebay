import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/profile/presentation/pages/blocked_users_page.dart';
import 'package:freebay/features/notifications/presentation/pages/notifications_page.dart';
import 'package:freebay/features/social/presentation/pages/my_posts_page.dart';
import 'package:freebay/features/social/presentation/pages/my_stories_page.dart';
import 'package:freebay/features/product/presentation/pages/my_products_page.dart';
import 'package:freebay/features/social/presentation/pages/liked_posts_page.dart';
import 'package:freebay/features/profile/presentation/pages/favorites_page.dart';
import 'package:freebay/features/profile/presentation/pages/saved_posts_page.dart';
import 'package:freebay/features/profile/presentation/pages/purchases_page.dart';
import 'package:freebay/features/payments/presentation/pages/payment_page.dart';
import 'package:freebay/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:freebay/features/profile/presentation/pages/followers_page.dart';
import 'package:freebay/features/profile/presentation/pages/following_page.dart';
import 'package:freebay/features/reviews/presentation/pages/user_reviews_page.dart';
import 'package:freebay/features/reviews/presentation/pages/create_review_page.dart';

final List<RouteBase> profileRoutes = [
  appCupertinoRoute(
    AppRoutes.profileBlocked,
    (context, state) => const BlockedUsersPage(),
  ),
  appCupertinoRoute(
    AppRoutes.notifications,
    (context, state) => const NotificationsPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profilePosts,
    (context, state) =>
        MyPostsPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
  ),
  appCupertinoRoute(
    AppRoutes.profileStories,
    (context, state) =>
        MyStoriesPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
  ),
  appCupertinoRoute(
    AppRoutes.profileProducts,
    (context, state) => const MyProductsPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profileLiked,
    (context, state) => const LikedPostsPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profileFavorites,
    (context, state) => const FavoritesPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profileSaved,
    (context, state) => const SavedPostsPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profilePurchases,
    (context, state) => const PurchasesPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profilePayment,
    (context, state) => const PaymentPage(),
  ),
  appCupertinoRoute(
    AppRoutes.profileEdit,
    (context, state) => const EditProfilePage(),
  ),
  appCupertinoRoute(
    AppRoutes.profileFollowers,
    (context, state) =>
        FollowersPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
  ),
  appCupertinoRoute(
    AppRoutes.profileFollowing,
    (context, state) =>
        FollowingPage(userId: state.uri.queryParameters['userId'] ?? 'me'),
  ),
  appCupertinoRoute(
    AppRoutes.userReviews,
    (context, state) => UserReviewsPage(
      userId: state.pathParameters['id']!,
      userName: state.uri.queryParameters['name'],
    ),
  ),
  appCupertinoRoute(AppRoutes.createReview, (context, state) {
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
  }),
];
