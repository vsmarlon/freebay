import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay_design_system/freebay_design_system.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

String _currentLocation = '/';

void updateCurrentLocation(String location) {
  _currentLocation = location;
}

Map<String, String> _labels(BuildContext context) {
  final strings = l10n(context);
  return {
    AppRoutes.feed: strings.feedTitle,
    AppRoutes.explore: strings.navExplore,
    AppRoutes.products: strings.productTitle,
    AppRoutes.wallet: strings.walletTitle,
    AppRoutes.chat: strings.chatTitle,
    AppRoutes.profile: strings.navProfile,
    AppRoutes.createPost: strings.feedCreatePost,
    AppRoutes.postDetails: strings.feedPostTitle,
    AppRoutes.commentDetails: strings.feedComments,
    AppRoutes.postSearch: strings.commonSearch,
    AppRoutes.createProduct: strings.productCreateListing,
    AppRoutes.productDetail: strings.productTitle,
    '${AppRoutes.productDetail}/edit': strings.productEditListing,
    AppRoutes.profileEdit: strings.profileEdit,
    AppRoutes.profileBlocked: strings.profileBlockedUsersTitle,
    AppRoutes.profileSaved: strings.profileSaved,
    AppRoutes.profilePosts: strings.feedMyPostsTitle,
    AppRoutes.profileStories: strings.feedMyStoriesTitle,
    AppRoutes.profileLiked: strings.feedLikedPostsTitle,
    AppRoutes.profileProducts: strings.productMyListings,
    AppRoutes.profileFavorites: strings.profileFavoritesTitle,
    AppRoutes.profilePurchases: strings.profilePurchasesTitle,
    AppRoutes.profilePayment: strings.paymentPageTitle,
    AppRoutes.profileFollowers: strings.profileFollowers,
    AppRoutes.profileFollowing: strings.profileFollowing,
    AppRoutes.chatNew: strings.chatNewTitle,
    AppRoutes.chatArchived: strings.chatArchivedTitle,
    AppRoutes.chatConversation: strings.chatTitle,
    AppRoutes.cart: strings.cartTitle,
    AppRoutes.checkoutCart: strings.cartCheckoutTitle,
    AppRoutes.orderDetail: strings.ordersDetails,
    AppRoutes.userReviews: strings.reviewsTitle,
    AppRoutes.createReview: strings.reviewsCreateTitle,
    AppRoutes.disputes: strings.disputesMyTitle,
    AppRoutes.disputeDetail: strings.disputeDetailTitle,
    AppRoutes.createDispute: strings.ordersDispute,
    AppRoutes.notifications: strings.notificationsTitle,
    AppRoutes.faq: strings.chatFaqTitle,
  };
}

bool _matches(String pattern, String location) {
  final p = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final l = location.split('/').where((s) => s.isNotEmpty).toList();

  // Must have same number of segments
  if (p.length != l.length) return false;

  for (var i = 0; i < p.length; i++) {
    // Skip parameter segments (start with ':')
    if (p[i].startsWith(':')) continue;

    // Exact match required for static segments
    if (p[i] != l[i]) return false;
  }
  return true;
}

/// More lenient match that allows partial prefix matching for breadcrumbs.
/// Returns true if the pattern matches the beginning of the location.
bool _matchesPrefix(String pattern, String location) {
  final p = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final l = location.split('/').where((s) => s.isNotEmpty).toList();

  // Pattern must be shorter or equal to location
  if (p.length > l.length) return false;

  for (var i = 0; i < p.length; i++) {
    // Skip parameter segments
    if (p[i].startsWith(':')) continue;

    // Exact match required for static segments
    if (p[i] != l[i]) return false;
  }
  return true;
}

MapEntry<String, String>? _lookup(Map<String, String> labels, String location) {
  // First try exact match
  if (labels.containsKey(location)) {
    return MapEntry(location, labels[location]!);
  }

  // Then try pattern matching
  for (final e in labels.entries) {
    if (_matches(e.key, location)) return e;
  }

  return null;
}

/// Look up a breadcrumb label for a path segment, handling nested routes.
MapEntry<String, String>? _lookupBreadcrumb(
  Map<String, String> labels,
  String location,
) {
  // First try exact match
  if (labels.containsKey(location)) {
    return MapEntry(location, labels[location]!);
  }

  // Try pattern matching (exact segment count)
  for (final e in labels.entries) {
    if (_matches(e.key, location)) return e;
  }

  // Try prefix matching for nested routes (e.g., /post/:id for /post/:id/comments)
  MapEntry<String, String>? bestMatch;
  int bestLength = 0;

  for (final e in labels.entries) {
    if (_matchesPrefix(e.key, location)) {
      final segments = e.key.split('/').where((s) => s.isNotEmpty).length;
      if (segments > bestLength) {
        bestLength = segments;
        bestMatch = e;
      }
    }
  }

  return bestMatch;
}

String _concretize(String pattern, String location) {
  final p = pattern.split('/').where((s) => s.isNotEmpty).toList();
  final l = location.split('/').where((s) => s.isNotEmpty).toList();
  return '/${[for (var i = 0; i < p.length; i++) p[i].startsWith(':') && i < l.length ? l[i] : p[i]].join('/')}';
}

extension BreadcrumbX on BuildContext {
  List<BreadcrumbItem> get breadcrumbs {
    final location = GoRouter.maybeOf(this) == null
        ? Uri.parse(_currentLocation).path
        : GoRouterState.of(this).uri.path;
    final labels = _labels(this);
    final segs = location.split('/').where((s) => s.isNotEmpty).toList();
    final items = <BreadcrumbItem>[];
    final ctx = this;

    // Build breadcrumb items from path segments
    for (var i = 1; i <= segs.length; i++) {
      final prefix = '/${segs.sublist(0, i).join('/')}';
      final entry = _lookupBreadcrumb(labels, prefix);

      if (entry != null) {
        // Concretize the path (replace :id with actual value)
        final path = _concretize(entry.key, location);

        // Skip duplicate entries (e.g., /post/:id appearing twice)
        if (items.isNotEmpty && items.last.label == entry.value) continue;

        items.add(
          BreadcrumbItem(
            label: entry.value,
            onTap: () => GoRouter.of(ctx).go(path),
          ),
        );
      }
    }

    if (items.isEmpty) return [];

    // Add current page as last item (non-clickable)
    final current = _lookup(labels, location);

    // Avoid duplicate last item
    if (current != null && items.last.label != current.value) {
      items.add(BreadcrumbItem(label: current.value));
    }

    return items;
  }
}
