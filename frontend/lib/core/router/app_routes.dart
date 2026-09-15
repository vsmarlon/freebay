class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String completeProfile = '/complete-profile';
  static const String recoverPassword = '/recover-password';
  static const String resetPassword = '/reset-password';
  static const String onboarding = '/onboarding';
  static const String welcome = '/welcome';
  static const String createPost = '/create-post';
  static const String postDetails = '/post/:id';
  static const String postSearch = '/posts/search';
  static const String peopleSearch = '/people/search';
  static const String createProduct = '/products/create';
  static const String productDetail = '/products/:id';
  static const String editProduct = 'edit';
  static const String story = '/story';
  static const String createStory = '/create-story';
  static const String userProfile = '/user/:id';
  static const String feed = '/feed';
  static const String explore = '/explore';
  static const String products = '/products';
  static const String wallet = '/wallet';
  static const String chat = '/chat';
  static const String profile = '/profile';
  static const String chatNew = '/chat/new';
  static const String chatArchived = '/chat/archived';
  static const String chatConversation = '/chat/:chatId';
  static const String chatDetails = '/chat/:chatId/details';
  static const String profileBlocked = '/profile/blocked';
  static const String faq = '/faq';
  static const String notifications = '/notifications';
  static const String profilePosts = '/profile/posts';
  static const String profileStories = '/profile/stories';
  static const String profileProducts = '/profile/products';
  static const String profileLiked = '/profile/liked';
  static const String profileFavorites = '/profile/favorites';
  static const String profileSaved = '/profile/saved';
  static const String profilePurchases = '/profile/purchases';
  static const String profilePayment = '/profile/payment';
  static const String profileEdit = '/profile/edit';
  static const String profileFollowers = '/profile/followers';
  static const String profileFollowing = '/profile/following';
  static const String cart = '/cart';
  static const String checkoutCart = '/checkout/cart';
  static const String orderDetail = '/orders/:orderId';
  static const String userReviews = '/user/:id/reviews';
  static const String createReview = '/reviews/create';
  static const String disputes = '/disputes';
  static const String disputeDetail = '/disputes/:disputeId';
  static const String createDispute = '/disputes/create/:orderId';
  static const String checkout = '/checkout';
  static const String orders = '/orders';
  static const String reviews = '/reviews';
  static const String wildCard = '/:path(.*)';
  static const String imageEditor = '/image-editor';

  // ── Parameterized builders: always navigate through these, never by
  // hand-writing a '/path/$id' literal at the call site. ──

  static String postPath(String id) => '/post/$id';
  static String productPath(String id) => '/products/$id';
  static String productEditPath(String id) => '/products/$id/edit';
  static String userPath(String id) => '/user/$id';
  static String userReviewsPath(String id) => '/user/$id/reviews';
  static String orderPath(String id) => '/orders/$id';
  static String chatPath(String id) => '/chat/$id';
  static String chatNewWith(String targetUserId, String productId) =>
      '$chatNew?targetUserId=${Uri.encodeComponent(targetUserId)}&productId=${Uri.encodeComponent(productId)}';
  static String chatDetailsPath(String id) => '/chat/$id/details';
  static String disputePath(String id) => '/disputes/$id';
  static String createDisputePath(String orderId) =>
      '/disputes/create/$orderId';

  static String followersWith(String userId) =>
      '$profileFollowers?userId=${Uri.encodeComponent(userId)}';
  static String followingWith(String userId) =>
      '$profileFollowing?userId=${Uri.encodeComponent(userId)}';
  static String storyAt(int index) => '$story?index=$index';
  static String peopleSearchWith(String query) =>
      '$peopleSearch?q=${Uri.encodeComponent(query)}';
  static String postSearchWith(String query) =>
      '$postSearch?q=${Uri.encodeComponent(query)}';
}
