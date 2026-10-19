import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/social/presentation/pages/create_post_page.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/social/presentation/pages/post_details_page.dart';
import 'package:freebay/features/social/presentation/pages/comment_context_page.dart';
import 'package:freebay/features/social/presentation/pages/post_search_page.dart';
import 'package:freebay/features/social/presentation/pages/people_search_page.dart';
import 'package:freebay/features/stories/stories.dart';
import 'package:freebay/features/profile/presentation/pages/user_profile_page.dart';

final List<RouteBase> socialRoutes = [
  appCupertinoRoute(
    AppRoutes.createPost,
    (context, state) => CreatePostPage(
      quoteSource: state.extra is QuoteSource
          ? state.extra! as QuoteSource
          : null,
    ),
  ),
  appCupertinoRoute(
    AppRoutes.postDetails,
    (context, state) => PostDetailsPage(postId: state.pathParameters['id']!),
  ),
  appCupertinoRoute(
    AppRoutes.commentDetails,
    (context, state) => CommentContextPage(
      postId: state.pathParameters['postId']!,
      commentId: state.pathParameters['commentId']!,
    ),
  ),
  appCupertinoRoute(
    AppRoutes.postSearch,
    (context, state) => const PostSearchPage(),
  ),
  appCupertinoRoute(
    AppRoutes.peopleSearch,
    (context, state) => const PeopleSearchPage(),
  ),
  _storyRoute(
    AppRoutes.story,
    (context, state) =>
        StoryViewerWrapper(indexParam: state.uri.queryParameters['index']),
  ),
  _storyRoute(
    AppRoutes.storyHighlight,
    (context, state) =>
        HighlightStoryViewerWrapper(id: state.pathParameters['id']!),
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

GoRoute _storyRoute(
  String path,
  Widget Function(BuildContext context, GoRouterState state) builder,
) => GoRoute(
  path: path,
  pageBuilder: (context, state) => CustomTransitionPage<void>(
    key: state.pageKey,
    opaque: false,
    barrierColor: Colors.transparent,
    transitionDuration: AppMotion.forContext(context, AppMotion.base),
    reverseTransitionDuration: AppMotion.forContext(context, AppMotion.base),
    child: builder(context, state),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
  ),
);
