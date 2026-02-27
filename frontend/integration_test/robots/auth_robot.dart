import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page-object helper for authentication flows
class AuthRobot {
  final WidgetTester tester;

  AuthRobot(this.tester);

  /// Wait for splash screen to finish and navigate away
  Future<void> waitForSplash() async {
    // Splash has a 1800ms delay + animation
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Verify we're on the login page
  Future<void> expectLoginPage() async {
    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
  }

  /// Enter email and password
  Future<void> enterCredentials(String email, String password) async {
    await tester.enterText(
      find.byType(TextField).at(0),
      email,
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      password,
    );
    await tester.pump();
  }

  /// Toggle "Manter logado" checkbox
  Future<void> toggleRememberMe() async {
    final checkbox = find.byType(Checkbox);
    expect(checkbox, findsOneWidget);
    await tester.tap(checkbox);
    await tester.pump();
  }

  /// Tap the login button
  Future<void> tapLogin() async {
    final loginButton = find.widgetWithText(ElevatedButton, 'Entrar');
    if (loginButton.evaluate().isEmpty) {
      // AppButton may not be an ElevatedButton — find by text
      final allEntrar = find.text('Entrar');
      // The button labelled "Entrar" that is tappable
      await tester.tap(allEntrar.last);
    } else {
      await tester.tap(loginButton);
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Tap "Entrar como convidado"
  Future<void> tapGuestLogin() async {
    final guestButton = find.text('Entrar como convidado');
    expect(guestButton, findsOneWidget);
    await tester.tap(guestButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Tap "Criar conta" to navigate to register page
  Future<void> tapCreateAccount() async {
    final createButton = find.text('Criar conta');
    expect(createButton, findsOneWidget);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
  }
}
