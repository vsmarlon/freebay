import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page-object helper for bottom-nav and in-app navigation
class NavigationRobot {
  final WidgetTester tester;

  NavigationRobot(this.tester);

  /// Verify we're on the feed page
  Future<void> expectFeedPage() async {
    expect(find.text('Freebay'), findsOneWidget);
    // Bottom nav should show Feed tab
    expect(find.text('Feed'), findsOneWidget);
  }

  /// Tap on a bottom navigation tab by label
  Future<void> tapTab(String label) async {
    final tab = find.text(label);
    expect(tab, findsOneWidget);
    await tester.tap(tab);
    await tester.pumpAndSettle();
  }

  /// Verify the Explore/Products page is showing
  Future<void> expectExplorePage() async {
    expect(find.text('Explorar'), findsWidgets);
  }

  /// Verify the wallet page is showing
  Future<void> expectWalletPage() async {
    expect(find.text('Carteira'), findsWidgets);
  }

  /// Verify the chat page is showing
  Future<void> expectChatPage() async {
    expect(find.text('Chat'), findsWidgets);
  }

  /// Verify the profile page is showing
  Future<void> expectProfilePage() async {
    expect(find.text('Perfil'), findsWidgets);
  }

  /// Tap the "Adicionar" story button on the feed
  Future<void> tapAddStory() async {
    final addButton = find.text('Adicionar');
    expect(addButton, findsOneWidget);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
  }

  /// Tap on the first post in the feed (if present)
  Future<void> tapFirstPost() async {
    // SocialPost cards are wrapped in GestureDetector
    final posts = find.byType(GestureDetector);
    expect(posts, findsWidgets);
    await tester.tap(posts.first);
    await tester.pumpAndSettle();
  }

  /// Go back using the back button
  Future<void> goBack() async {
    final backButton = find.byType(BackButton);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
      return;
    }
    // Try icon button with arrow_back
    final arrowBack = find.byIcon(Icons.arrow_back);
    if (arrowBack.evaluate().isNotEmpty) {
      await tester.tap(arrowBack);
      await tester.pumpAndSettle();
    }
  }
}
