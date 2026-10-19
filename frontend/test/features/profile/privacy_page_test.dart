import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/presentation/pages/privacy_page.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';

class _PrivacyRepository extends ProfileRepository {
  int deletionRequests = 0;
  final deletionTokens = <String>[];

  @override
  Future<Either<Failure, DateTime>> requestAccountDeletion({
    required String stepUpToken,
  }) async {
    deletionRequests++;
    deletionTokens.add(stepUpToken);
    return Right(DateTime.parse('2026-10-01T00:00:00.000Z'));
  }
}

class _StepUpAuthRepository extends AuthRepository {
  final requests = <({String purpose, Map<String, Object?> proof})>[];
  bool rejectNextProof = false;

  @override
  Future<Either<Failure, String>> createStepUp({
    required String purpose,
    String? resourceId,
    required Map<String, Object?> proof,
  }) async {
    requests.add((purpose: purpose, proof: proof));
    if (rejectNextProof) {
      rejectNextProof = false;
      return const Left(InvalidCredentialsFailure());
    }
    return const Right('fresh-proof');
  }
}

class _PrivacyHarness {
  const _PrivacyHarness({
    required this.repository,
    required this.authRepository,
  });

  final _PrivacyRepository repository;
  final _StepUpAuthRepository authRepository;
}

class _PrivacyAuthController extends AuthController {
  static bool didForceLogout = false;

  @override
  AsyncValue<UserEntity?> build() => const AsyncValue.data(
    UserEntity(id: 'privacy-test-user', email: 'privacy@example.com'),
  );

  @override
  Future<void> forceLogout() async {
    didForceLogout = true;
    state = const AsyncValue.data(null);
  }
}

Future<_PrivacyHarness> _pumpPrivacyPage(WidgetTester tester) async {
  FlutterSecureStorage.setMockInitialValues({});
  const biometricChannel = MethodChannel('com.freebay.app/biometric_key');
  const appleChannel = MethodChannel(
    'com.aboutyou.dart_packages.sign_in_with_apple',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(biometricChannel, (call) async {
        if (call.method == 'hasKey') return false;
        return null;
      });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(appleChannel, (call) async => false);
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(biometricChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(appleChannel, null);
  });

  final repository = _PrivacyRepository();
  final authRepository = _StepUpAuthRepository();
  _PrivacyAuthController.didForceLogout = false;
  final router = GoRouter(
    initialLocation: AppRoutes.profilePrivacy,
    routes: [
      GoRoute(
        path: AppRoutes.profilePrivacy,
        builder: (context, state) => PrivacyPage(repository: repository),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const Scaffold(body: Text('Logged out')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_PrivacyAuthController.new),
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _PrivacyHarness(
    repository: repository,
    authRepository: authRepository,
  );
}

Future<void> _openPasswordProof(WidgetTester tester) async {
  await tester.tap(find.text('REQUEST ACCOUNT DELETION'));
  await tester.pumpAndSettle();
  await tester.tap(
    find.widgetWithText(CupertinoDialogAction, 'REQUEST ACCOUNT DELETION'),
  );
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.byType(TextFormField), findsOneWidget);
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cancelling step-up does not request account deletion', (
    tester,
  ) async {
    final harness = await _pumpPrivacyPage(tester);
    await _openPasswordProof(tester);
    await _pumpFrames(tester);
    await tester.tap(find.widgetWithText(AppButton, 'Cancel'));
    await _pumpFrames(tester);

    expect(harness.authRepository.requests, isEmpty);
    expect(harness.repository.deletionRequests, 0);
  });

  testWidgets('rejected password proof does not request account deletion', (
    tester,
  ) async {
    final harness = await _pumpPrivacyPage(tester);
    harness.authRepository.rejectNextProof = true;
    await _openPasswordProof(tester);
    await tester.enterText(find.byType(TextFormField), 'wrong-password');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _pumpFrames(tester);

    expect(harness.authRepository.requests.single.proof, {
      'kind': 'password',
      'password': 'wrong-password',
    });
    expect(harness.repository.deletionRequests, 0);
  });

  testWidgets('fresh password proof is purpose-bound and forwarded once', (
    tester,
  ) async {
    final harness = await _pumpPrivacyPage(tester);
    await _openPasswordProof(tester);
    await tester.enterText(find.byType(TextFormField), 'current-password');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await _pumpFrames(tester);

    expect(harness.authRepository.requests, hasLength(1));
    expect(harness.authRepository.requests.single.purpose, 'delete_account');
    expect(harness.authRepository.requests.single.proof, {
      'kind': 'password',
      'password': 'current-password',
    });
    expect(harness.repository.deletionRequests, 1);
    expect(harness.repository.deletionTokens, ['fresh-proof']);
    expect(_PrivacyAuthController.didForceLogout, isTrue);
    expect(find.text('Logged out'), findsOneWidget);
  });
}
