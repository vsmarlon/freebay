import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/features/chat/presentation/widgets/location_message_bubble.dart';

void main() {
  testWidgets('renders unavailable for malformed canonical coordinates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LocationMessageBubble(
            isMe: true,
            metadata: {
              'latitude': 'not-a-number',
              'longitude': 2,
              'lat': 1,
              'lng': 2,
              'address': 42,
              'accuracyMeters': -1,
            },
          ),
        ),
      ),
    );

    expect(find.text('Localização indisponível'), findsOneWidget);
  });
}
