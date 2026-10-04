import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/presentation/providers/feed_provider.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_list.dart';
import 'package:freebay/features/social/data/entities/post_entity.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/social/presentation/widgets/feed_post_item.dart';
import 'package:freebay_design_system/components/shimmer_skeleton.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('empty initial feed shows skeletons rather than a spinner', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              FeedPostList(
                state: const FeedState(isLoading: true),
                onRetry: () {},
                emptyState: const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ShimmerBlock), findsNWidgets(9));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('loaded feed post fits at ${scale}x text scale', (
      tester,
    ) async {
      final post = PostEntity(
        id: 'post-long',
        userId: 'seller-long',
        createdAt: DateTime.utc(2026, 9, 30),
        user: const UserEntity(
          id: 'seller-long',
          displayName:
              'Vendedor com nome muito longo para leitura acessível em telas pequenas',
        ),
        content: List.filled(
          20,
          'Descrição longa do anúncio com informações importantes para o comprador.',
        ).join(' '),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: FeedPostItem(post: post)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Descrição longa', findRichText: true),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
