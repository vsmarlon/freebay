import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/social/data/entities/story_entity.dart';
import 'package:freebay/features/social/presentation/widgets/story_preview_view.dart';

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

    expect(find.text('AMIGOS PRÓXIMOS'), findsOneWidget);
    await tester.tap(find.text('AMIGOS PRÓXIMOS'));
    await tester.pump();
    expect(selected, StoryAudience.closeFriends);
    expect(
      find.text('Somente sua lista poderá ver esta história.'),
      findsOneWidget,
    );
  });
}
