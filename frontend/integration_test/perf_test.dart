import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/components/app_shell_scaffold_key.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_list_tile.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:freebay/features/product/presentation/pages/product_detail_page.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay/features/stories/stories.dart';
import 'package:freebay/main.dart' as app;
import 'package:integration_test/integration_test.dart';

const flow = String.fromEnvironment('PERF_FLOW');
const _minimumFeedPosts = 30;

Future<void> until(
  WidgetTester tester,
  bool Function() ready,
  String fixture,
) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (ready()) return;
  }
  throw StateError(
    'Perf fixture missing: $fixture (see docs/DEVICE_TESTING.md)',
  );
}

Finder scrollableWithin(Finder page) => find
    .descendant(
      of: page,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            axisDirectionToAxis(widget.axisDirection) == Axis.vertical,
      ),
    )
    .first;

Future<void> scroll(WidgetTester tester, Finder target) async {
  final initial = tester.state<ScrollableState>(target).position.pixels;
  for (var i = 0; i < 8; i++) {
    await tester.fling(target, const Offset(0, -650), 1000);
    await tester.pump(const Duration(milliseconds: 350));
  }
  if (tester.state<ScrollableState>(target).position.pixels == initial) {
    throw StateError('Perf fixture did not scroll: $flow');
  }
}

Future<void> loadFeedForCoverage(ProviderContainer container) async {
  for (var page = 0; page < 10; page++) {
    final state = container.read(feedProvider);
    if (state.error != null) {
      throw StateError('Feed pagination failed: ${state.error}');
    }
    if (state.posts.length >= _minimumFeedPosts) return;
    if (!state.hasMore) {
      throw StateError(
        'Perf fixture has only ${state.posts.length} feed posts; '
        'need at least $_minimumFeedPosts',
      );
    }

    final previousCount = state.posts.length;
    await container.read(feedProvider.notifier).loadFeed();
    final next = container.read(feedProvider);
    if (next.error != null) {
      throw StateError('Feed pagination failed: ${next.error}');
    }
    if (next.posts.length <= previousCount) {
      throw StateError(
        'Feed pagination made no progress at ${next.posts.length} posts',
      );
    }
  }
  final loaded = container.read(feedProvider).posts.length;
  if (loaded >= _minimumFeedPosts) return;
  throw StateError(
    'Feed pagination stopped at $loaded posts; '
    'need at least $_minimumFeedPosts',
  );
}

Future<void> scrollFeedCoverage(
  WidgetTester tester,
  Finder target,
  ProviderContainer container,
) async {
  final postIds = <String>{};
  var noProgress = 0;
  for (
    var attempt = 0;
    attempt < 120 && postIds.length < _minimumFeedPosts;
    attempt++
  ) {
    final position = tester.state<ScrollableState>(target).position;
    final previousOffset = position.pixels;
    final previousCoverage = postIds.length;
    await tester.fling(target, const Offset(0, -650), 1000);
    await tester.pump(const Duration(milliseconds: 350));

    postIds.addAll(
      tester
          .widgetList<FeedPostItem>(find.byType(FeedPostItem))
          .map((item) => item.post.id),
    );
    final state = container.read(feedProvider);
    if (state.error != null) {
      throw StateError('Feed scroll pagination failed: ${state.error}');
    }

    final nextOffset = tester.state<ScrollableState>(target).position.pixels;
    if (nextOffset == previousOffset && postIds.length == previousCoverage) {
      noProgress++;
      if (tester.state<ScrollableState>(target).position.extentAfter == 0 ||
          noProgress >= 3) {
        throw StateError(
          'Feed scroll stopped after ${postIds.length} distinct posts',
        );
      }
    } else {
      noProgress = 0;
    }
  }

  if (postIds.length < _minimumFeedPosts) {
    throw StateError(
      'Feed scroll covered ${postIds.length} distinct posts; '
      'need at least $_minimumFeedPosts',
    );
  }
  debugPrint(
    'feed_scroll coverage: loaded=${container.read(feedProvider).posts.length}, '
    'distinctMounted=${postIds.length}',
  );
}

Future<void> waitForDrawerState(WidgetTester tester, bool isOpen) async {
  for (var frame = 0; frame < 50; frame++) {
    if (appShellScaffoldKey.currentState?.isDrawerOpen == isOpen) return;
    await tester.pump(const Duration(milliseconds: 16));
  }
  throw StateError('Drawer did not become ${isOpen ? 'open' : 'closed'}');
}

Future<void> openDrawer(WidgetTester tester, String interaction) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  final point = switch (interaction) {
    'header_tap' => tester.getCenter(find.byIcon(Icons.menu)),
    'edge_right_drag' => Offset(1, size.height * .45),
    _ =>
      tester.getTopLeft(find.byType(FeedPostItem).first) +
          const Offset(24, 100),
  };
  if (interaction == 'header_tap') {
    await tester.tapAt(point);
  } else {
    final gesture = await tester.startGesture(point);
    for (var step = 0; step < 8; step++) {
      await gesture.moveBy(const Offset(18, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
  }
  await waitForDrawerState(tester, true);
}

Future<void> closeDrawer(WidgetTester tester) async {
  appShellScaffoldKey.currentState!.closeDrawer();
  await waitForDrawerState(tester, false);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile $flow on the real FreeBay app', (tester) async {
    if (!{
      'feed_scroll',
      'explore_scroll',
      'chat_scroll',
      'story_view',
      'product_detail',
      'drawer_open',
    }.contains(flow)) {
      throw StateError('Unknown PERF_FLOW: $flow');
    }
    app.main();
    await until(
      tester,
      () => find.byType(app.FreeBayApp).evaluate().isNotEmpty,
      'app bootstrap',
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(app.FreeBayApp)),
    );
    await until(
      tester,
      () => !container.read(isInitialAuthLoadingProvider),
      'auth/session hydration',
    );

    if (flow == 'drawer_open') {
      if (container.read(authControllerProvider).value == null) {
        throw StateError('Perf fixture missing: signed-in session for drawer');
      }
      appRouter.go(AppRoutes.feed);
      await until(tester, () {
        final state = container.read(feedProvider);
        return !state.isLoading &&
            !state.isRefreshing &&
            !state.isStale &&
            state.error == null &&
            state.posts.length >= 3;
      }, 'authenticated feed with at least three fresh server posts');
      final cases = <Map<String, Object?>>[];
      binding.reportData ??= <String, dynamic>{};
      binding.reportData!['drawer_cases'] = cases;
      binding.reportData!['drawer_native_input_latency'] =
          'unsupported: integration_test FrameTiming has no native input timestamp';
      final interactions = [
        ('header_tap', 'first_after_app_launch'),
        ('header_tap', 'repeat_same_process'),
        ('edge_right_drag', 'repeat_same_process'),
        ('edge_right_drag', 'repeat_same_process'),
        ('feed_content_right_drag', 'repeat_same_process'),
        ('feed_content_right_drag', 'repeat_same_process'),
      ];
      for (var index = 0; index < interactions.length; index++) {
        final (interaction, opening) = interactions[index];
        final frameReportKey = 'drawer_case_$index';
        await binding.watchPerformance(
          () => openDrawer(tester, interaction),
          reportKey: frameReportKey,
        );
        cases.add({
          'interaction': interaction,
          'opening': opening,
          'open': appShellScaffoldKey.currentState?.isDrawerOpen == true,
          'frame_report_key': frameReportKey,
          if (interaction == 'edge_right_drag' ||
              interaction == 'feed_content_right_drag')
            'cold_status': 'pending_separate_profile_launch',
        });
        binding.reportData!['drawer_cases'] = cases;
        await closeDrawer(tester);
      }
    } else if (flow == 'feed_scroll') {
      appRouter.go(AppRoutes.feed);
      await until(tester, () {
        final state = container.read(feedProvider);
        return !state.isLoading &&
            !state.isRefreshing &&
            !state.isStale &&
            state.error == null &&
            state.posts.length >= 3;
      }, 'at least three fresh server feed posts (seed and start backend)');
      await loadFeedForCoverage(container);
      final list = scrollableWithin(find.byType(FeedPage));
      await until(
        tester,
        () => tester.state<ScrollableState>(list).position.maxScrollExtent > 0,
        'scrollable feed with real posts',
      );
      await binding.watchPerformance(
        () => scrollFeedCoverage(tester, list, container),
      );
    } else if (flow == 'explore_scroll' || flow == 'product_detail') {
      appRouter.go(AppRoutes.explore);
      await until(tester, () {
        final grid = find.byType(ProductResultsGrid);
        return grid.evaluate().isNotEmpty &&
            tester.widget<ProductResultsGrid>(grid).products.length >= 4;
      }, 'at least four real products in Explore');
      final grid = find.byType(ProductResultsGrid);
      if (flow == 'explore_scroll') {
        final list = scrollableWithin(grid);
        await until(
          tester,
          () =>
              tester.state<ScrollableState>(list).position.maxScrollExtent > 0,
          'scrollable product grid',
        );
        await binding.watchPerformance(() => scroll(tester, list));
      } else {
        final product = tester.widget<ProductResultsGrid>(grid).products.first;
        await binding.watchPerformance(() async {
          appRouter.go(AppRoutes.productPath(product.id));
          await until(
            tester,
            () =>
                find.byType(ProductDetailPage).evaluate().isNotEmpty &&
                find.text(product.title).evaluate().isNotEmpty,
            'loaded product detail',
          );
          await tester.pump(const Duration(seconds: 1));
        });
      }
    } else if (flow == 'chat_scroll') {
      if (container.read(authControllerProvider).value == null) {
        throw StateError(
          'Perf fixture missing: signed-in account with a long real conversation',
        );
      }
      appRouter.go(AppRoutes.chat);
      await until(
        tester,
        () => find.byType(ChatListTile).evaluate().isNotEmpty,
        'signed-in account with an existing conversation',
      );
      await tester.tap(find.byType(ChatListTile).first);
      await until(
        tester,
        () =>
            find.byType(ChatConversationPage).evaluate().isNotEmpty &&
            find.byType(ChatMessageList).evaluate().isNotEmpty,
        'conversation with real messages',
      );
      final list = scrollableWithin(find.byType(ChatMessageList));
      await until(
        tester,
        () => tester.state<ScrollableState>(list).position.maxScrollExtent > 0,
        'enough real messages to scroll',
      );
      await binding.watchPerformance(() => scroll(tester, list));
    } else {
      if (container.read(authControllerProvider).value == null) {
        throw StateError('Perf fixture missing: signed-in session for stories');
      }
      appRouter.go(AppRoutes.storyAt(0));
      await until(
        tester,
        () =>
            find.byType(StoryViewerPage).evaluate().isNotEmpty &&
            find.byType(StoryPage).evaluate().isNotEmpty &&
            tester
                    .widget<StoryPage>(find.byType(StoryPage).first)
                    .story
                    .mediaType ==
                StoryMediaType.image,
        'real image story',
      );
      await until(
        tester,
        () => tester
            .widget<StoryPage>(find.byType(StoryPage).first)
            .animationController
            .isAnimating,
        'image loaded and story animation running',
      );
      await binding.watchPerformance(() async {
        await tester.pump(const Duration(seconds: 3));
      });
    }
  });
}
