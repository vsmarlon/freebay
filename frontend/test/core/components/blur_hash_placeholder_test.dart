import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/components/blur_hash_placeholder.dart';

void main() {
  testWidgets('renders BlurHash for valid image metadata', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BlurHashPlaceholder(hash: 'LEHV6nWB2yk8pyo0adR*.7kCMdnj'),
        ),
      ),
    );

    expect(find.byType(BlurHash), findsOneWidget);
  });

  testWidgets('uses a static fallback for malformed or missing hashes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BlurHashPlaceholder(
            hash: 'not-valid',
            fallback: Text('static fallback'),
          ),
        ),
      ),
    );

    expect(find.byType(BlurHash), findsNothing);
    expect(find.text('static fallback'), findsOneWidget);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BlurHashPlaceholder(hash: null, fallback: Text('legacy image')),
        ),
      ),
    );
    expect(find.byType(BlurHash), findsNothing);
    expect(find.text('legacy image'), findsOneWidget);
  });
}
