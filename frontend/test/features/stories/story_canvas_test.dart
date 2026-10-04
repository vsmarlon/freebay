import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/stories/data/entities/story_entity.dart';
import 'package:freebay/features/stories/presentation/widgets/story_canvas.dart';

void main() {
  testWidgets('renders and moves a selected text block', (tester) async {
    var blocks = [
      const StoryTextBlockEntity(
        id: 'one',
        text: 'Hello',
        x: 0.5,
        y: 0.5,
        scale: 1,
        rotation: 0,
        color: 0xffffffff,
        style: StoryTextStyle.classic,
        zIndex: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: StoryCanvas(
            editable: true,
            blocks: blocks,
            background: const ColoredBox(color: Colors.black),
            onChanged: (value) => blocks = value,
          ),
        ),
      ),
    );

    expect(find.text('Hello'), findsOneWidget);
    await tester.tap(find.text('Hello'));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(find.text('Hello'), const Offset(40, 20));
    await tester.pump(const Duration(milliseconds: 100));

    expect(blocks.single.x, greaterThan(0.5));
    expect(blocks.single.y, greaterThan(0.5));
  });
}
