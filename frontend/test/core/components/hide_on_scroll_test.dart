import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/hide_on_scroll.dart';

class _ScrollHarness extends StatefulWidget {
  const _ScrollHarness({super.key, required this.reverse});

  final bool reverse;

  @override
  State<_ScrollHarness> createState() => _ScrollHarnessState();
}

class _ScrollHarnessState extends State<_ScrollHarness>
    with TickerProviderStateMixin {
  late final controller = HideOnScrollController(vsync: this);
  final scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        AnimatedBuilder(
          animation: controller.animation,
          builder: (_, _) => Text('chrome ${controller.animation.value}'),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: controller.handleNotification,
            child: ListView.builder(
              controller: scrollController,
              reverse: widget.reverse,
              itemExtent: 80,
              itemCount: 40,
              itemBuilder: (_, index) => Text('row $index'),
            ),
          ),
        ),
      ],
    ),
  );
}

void main() {
  testWidgets('reversed chat scroll hides away from bottom and reveals back', (
    tester,
  ) async {
    final key = GlobalKey<_ScrollHarnessState>();
    await tester.pumpWidget(
      MaterialApp(home: _ScrollHarness(key: key, reverse: true)),
    );

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(key.currentState!.controller.animation.value, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(key.currentState!.controller.animation.value, 1);
  });

  testWidgets('programmatic scrolling does not hide chrome', (tester) async {
    final key = GlobalKey<_ScrollHarnessState>();
    await tester.pumpWidget(
      MaterialApp(home: _ScrollHarness(key: key, reverse: false)),
    );

    final scrolling = key.currentState!.scrollController.animateTo(
      800,
      duration: const Duration(milliseconds: 300),
      curve: Curves.linear,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await scrolling;
    await tester.pumpAndSettle();

    expect(key.currentState!.controller.animation.value, 1);
  });
}
