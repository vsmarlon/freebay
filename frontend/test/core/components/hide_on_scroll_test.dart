import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/hide_on_scroll.dart';

class _Harness extends StatefulWidget {
  const _Harness({required this.onController, required this.itemCount});

  final ValueChanged<HideOnScrollController> onController;
  final int itemCount;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> with TickerProviderStateMixin {
  late final HideOnScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = HideOnScrollController(vsync: this);
    widget.onController(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: NotificationListener<ScrollNotification>(
          onNotification: controller.handleNotification,
          child: ListView.builder(
            itemCount: widget.itemCount,
            itemBuilder: (context, index) => SizedBox(
              height: 100,
              child: Text('Item $index'),
            ),
          ),
        ),
      ),
    );
  }
}

class _HorizontalHarness extends StatefulWidget {
  const _HorizontalHarness({required this.onController});

  final ValueChanged<HideOnScrollController> onController;

  @override
  State<_HorizontalHarness> createState() => _HorizontalHarnessState();
}

class _HorizontalHarnessState extends State<_HorizontalHarness>
    with TickerProviderStateMixin {
  late final HideOnScrollController controller;

  @override
  void initState() {
    super.initState();
    controller = HideOnScrollController(vsync: this);
    widget.onController(controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: controller.handleNotification,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 50,
        itemBuilder: (context, index) => SizedBox(
          width: 100,
          child: Text('Item $index'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('hides after scrolling down past the threshold', (tester) async {
    late HideOnScrollController controller;
    await tester.pumpWidget(
      _Harness(onController: (c) => controller = c, itemCount: 100),
    );
    await tester.pump();

    expect(controller.animation.value, 1.0);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(controller.animation.value, 0.0);
  });

  testWidgets('reveals after scrolling back up past the threshold', (tester) async {
    late HideOnScrollController controller;
    await tester.pumpWidget(
      _Harness(onController: (c) => controller = c, itemCount: 100),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(controller.animation.value, 0.0);

    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(controller.animation.value, 1.0);
  });

  testWidgets('ignores drags smaller than the threshold', (tester) async {
    late HideOnScrollController controller;
    await tester.pumpWidget(
      _Harness(onController: (c) => controller = c, itemCount: 100),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -8));
    await tester.pumpAndSettle();

    expect(controller.animation.value, 1.0);
  });

  testWidgets('never hides when the list fits within the viewport', (tester) async {
    late HideOnScrollController controller;
    await tester.pumpWidget(
      _Harness(onController: (c) => controller = c, itemCount: 2),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(controller.animation.value, 1.0);
  });

  testWidgets('reveals immediately once scrolled back to the top', (tester) async {
    late HideOnScrollController controller;
    await tester.pumpWidget(
      _Harness(onController: (c) => controller = c, itemCount: 100),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(controller.animation.value, 0.0);

    await tester.fling(find.byType(ListView), const Offset(0, 5000), 4000);
    await tester.pumpAndSettle();

    expect(controller.animation.value, 1.0);
  });

  testWidgets('ignores horizontal scroll notifications', (tester) async {
    late HideOnScrollController controller;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: _HorizontalHarness(onController: (c) => controller = c),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(controller.animation.value, 1.0);
  });
}
