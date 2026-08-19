import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/social/presentation/pages/create_post_page.dart';
import 'package:freebay/features/social/presentation/pages/post_details_page.dart';
import 'package:freebay/features/social/presentation/pages/post_search_page.dart';
import 'package:freebay/features/social/presentation/pages/people_search_page.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_wrapper.dart';
import 'package:freebay/features/social/presentation/pages/create_story_page.dart';
import 'package:freebay/features/profile/presentation/pages/user_profile_page.dart';

final List<RouteBase> socialRoutes = [
  appCupertinoRoute(
    AppRoutes.createPost,
    (context, state) => const CreatePostPage(),
  ),
  appCupertinoRoute(
    AppRoutes.postDetails,
    (context, state) => PostDetailsPage(postId: state.pathParameters['id']!),
  ),
  appCupertinoRoute(
    AppRoutes.postSearch,
    (context, state) => const PostSearchPage(),
  ),
  appCupertinoRoute(
    AppRoutes.peopleSearch,
    (context, state) => const PeopleSearchPage(),
  ),
  appSlideRoute(
    AppRoutes.story,
    (context, state) =>
        StoryViewerWrapper(indexParam: state.uri.queryParameters['index']),
  ),
  appCupertinoRoute(
    AppRoutes.createStory,
    (context, state) => const CreateStoryPage(),
  ),
  appCupertinoRoute(
    AppRoutes.userProfile,
    (context, state) => UserProfilePage(userId: state.pathParameters['id']!),
  ),
];
