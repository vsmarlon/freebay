import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/chat/presentation/pages/chat_conversation_page.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_list_tile.dart';
import 'package:freebay/features/chat/presentation/widgets/chat_message_list.dart';
import 'package:freebay/features/product/presentation/pages/product_detail_page.dart';
import 'package:freebay/features/product/presentation/widgets/product_results_grid.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/pages/feed_page.dart';
import 'package:freebay/features/social/presentation/pages/story_viewer_page.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/story_page.dart';
import 'package:freebay/main.dart' as app;
import 'package:integration_test/integration_test.dart';

const flow = String.fromEnvironment('PERF_FLOW');

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

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile $flow on the real FreeBay app', (tester) async {
    if (!{
      'feed_scroll',
      'explore_scroll',
      'chat_scroll',
      'story_view',
      'product_detail',
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

    if (flow == 'feed_scroll') {
      appRouter.go(AppRoutes.feed);
      await until(tester, () {
        final state = container.read(feedProvider);
        return !state.isLoading &&
            state.error == null &&
            state.posts.length >= 3;
      }, 'at least three real feed posts (seed and start backend)');
      final list = scrollableWithin(find.byType(FeedPage));
      await until(
        tester,
        () => tester.state<ScrollableState>(list).position.maxScrollExtent > 0,
        'scrollable feed with real posts',
      );
      await binding.watchPerformance(() => scroll(tester, list));
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
