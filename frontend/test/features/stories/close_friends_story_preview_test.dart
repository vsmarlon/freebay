import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/widgets/story_preview_view.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('a story creator can choose the close-friends audience', (
    tester,
  ) async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}freebay_close_friends_preview.png',
    );
    file.writeAsBytesSync(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/0ZkAAAAASUVORK5CYII=',
      ),
    );
    final caption = TextEditingController();
    addTearDown(() {
      caption.dispose();
      file.deleteSync();
    });

    var selected = StoryAudience.everyone;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) => StoryPreviewView(
            mediaPath: file.path,
            videoController: null,
            textBlocks: const [],
            selectedTextId: null,
            captionController: caption,
            isLoading: false,
            audience: selected,
            onAudienceChanged: (value) => setState(() => selected = value),
            onClose: () {},
            onUpload: () {},
            onBlocksChanged: (_) {},
            onSelected: (_) {},
            onAddText: () {},
            onRemoveText: () {},
            onCycleStyle: () {},
            onCycleColor: () {},
            onBringForward: () {},
          ),
        ),
      ),
    );

    final strings = AppLocalizations.of(
      tester.element(find.byType(StoryPreviewView)),
    );
    expect(find.text(strings.feedAudienceCloseFriends), findsOneWidget);
    await tester.tap(find.text(strings.feedAudienceCloseFriends));
    await tester.pump();
    expect(selected, StoryAudience.closeFriends);
    expect(find.text(strings.profileCloseFriendsDescription), findsOneWidget);
  });
}
