import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/data/repositories/stories_repository.dart';
import 'package:freebay/features/stories/presentation/pages/story_viewer_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:freebay/features/stories/presentation/providers/stories_provider.dart';
import 'package:freebay/features/stories/presentation/widgets/story_page.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';

class _StoryRepository extends StoriesRepository {
  @override
  Future<Either<Failure, void>> viewStory(String storyId) async =>
      const Right(null);
}

void main() {
  final now = DateTime.utc(2026, 9, 25);
  final group = StoryGroupEntity(
    user: const StoryUserEntity(id: 'user', displayName: 'Alice'),
    stories: [
      for (final id in ['first', 'second'])
        StoryGroupItem(
          id: id,
          imageUrl: 'https://example.test/$id.png',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 1)),
        ),
    ],
  );

  testWidgets(
    'a photo stays visible for seven seconds and long press pauses it',
    (tester) async {
      await tester.runAsync(() => _primeStoryImages(tester));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storiesRepositoryProvider.overrideWithValue(_StoryRepository()),
          ],
          child: MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StoryViewerPage(groups: [group]),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Alice'), findsOneWidget);

      final gesture = await tester.startGesture(const Offset(700, 400));
      await tester.pump();
      expect(
        tester
            .widget<StoryPage>(find.byType(StoryPage))
            .animationController
            .isAnimating,
        isFalse,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('first')), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      expect(find.byKey(const ValueKey('first')), findsOneWidget);
      await gesture.up();
      await tester.pump();
      expect(
        tester
            .widget<StoryPage>(find.byType(StoryPage))
            .animationController
            .isAnimating,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 6));
      expect(
        tester
            .widget<StoryPage>(find.byType(StoryPage))
            .animationController
            .value,
        greaterThan(0.75),
      );
      expect(find.byKey(const ValueKey('first')), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('second')), findsOneWidget);
      tester.binding.imageCache.clear();
    },
  );
}

Future<void> _primeStoryImages(WidgetTester tester) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(1, 1);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  final pngBytes = Uint8List.sublistView(png!.buffer.asUint8List());
  final cacheWidth = tester.view.physicalSize.width.ceil().clamp(1, 1440);
  for (final id in ['first', 'second']) {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    final provider = ResizeImage(
      NetworkImage('https://example.test/$id.png'),
      width: cacheWidth,
    );
    final key = await provider.obtainKey(ImageConfiguration.empty);
    imageCache.putIfAbsent(
      key,
      () => OneFrameImageStreamCompleter(
        Future.value(ImageInfo(image: frame.image)),
      ),
    );
  }
}
