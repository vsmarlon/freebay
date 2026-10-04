import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _ProfileAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    jsonEncode({
      'success': true,
      'data': {
        'id': 'owner-a',
        'displayName': 'Ada Example',
        'username': 'Ada_Example',
        'bio': 'Existing profile bio',
        'city': 'Recife',
        'state': 'PE',
        'cpf': '***.456.789-**',
      },
    }),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

class _QueuedProfileAdapter implements HttpClientAdapter {
  final requests = <Completer<ResponseBody>>[];
  final patches = <Object?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    if (options.method == 'PATCH') {
      patches.add(options.data);
      return Future.value(_profileResponse('owner-b', 'Saved B'));
    }
    final pending = Completer<ResponseBody>();
    requests.add(pending);
    return pending.future;
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _pumpUntilRequestCount(
  WidgetTester tester,
  _QueuedProfileAdapter adapter,
  int count,
) async {
  for (var i = 0; i < 10 && adapter.requests.length < count; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

Future<void> _pumpUntilPatchCount(
  WidgetTester tester,
  _QueuedProfileAdapter adapter,
  int count,
) async {
  for (var i = 0; i < 10 && adapter.patches.length < count; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

ResponseBody _profileResponse(String id, String displayName) =>
    ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': {
          'id': id,
          'displayName': displayName,
          'username': id.replaceAll('-', '_'),
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _SwitchableAuthController extends AuthController {
  _SwitchableAuthController(this.user);

  UserEntity? user;

  @override
  AsyncValue<UserEntity?> build() => AsyncValue.data(user);

  void switchTo(UserEntity next) {
    user = next;
    state = AsyncValue.data(next);
  }
}

class _TestHost extends ConsumerWidget {
  const _TestHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) => const EditProfilePage();
}

Future<void> _pumpPage(WidgetTester tester, ProviderContainer container) async {
  final router = GoRouter(
    initialLocation: '/host/edit',
    routes: [
      GoRoute(
        path: '/host',
        builder: (_, _) => const SizedBox.shrink(),
        routes: [GoRoute(path: 'edit', builder: (_, _) => const _TestHost())],
      ),
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'prefills own profile fields when the HTTP profile arrives after mount',
    (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      dio.httpClientAdapter = _ProfileAdapter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => TestAuthController(testUser(id: 'owner-a')),
            ),
            profileRepositoryProvider.overrideWithValue(
              ProfileRepository(client: dio),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EditProfilePage(),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.text('Ada Example'), findsOneWidget);
      expect(find.text('ada_example'), findsOneWidget);
      expect(find.text('Existing profile bio'), findsOneWidget);
      expect(find.text('Recife'), findsOneWidget);
      expect(find.text('PE'), findsOneWidget);
      expect(find.text('***.456.789-**'), findsOneWidget);
    },
  );

  testWidgets('same-owner refresh does not replace an unsaved draft', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    final adapter = _QueuedProfileAdapter();
    dio.httpClientAdapter = adapter;
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          () => TestAuthController(testUser(id: 'owner-a')),
        ),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    final profileSubscription = container.listen(
      profileFutureProvider('me'),
      (_, _) {},
    );
    addTearDown(profileSubscription.close);
    await _pumpPage(tester, container);
    await tester.pump(const Duration(seconds: 1));
    expect(adapter.requests, hasLength(1));
    adapter.requests[0].complete(_profileResponse('owner-a', 'Server name'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byType(TextFormField), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'My draft');
    container.invalidate(profileFutureProvider('me'));
    await _pumpUntilRequestCount(tester, adapter, 2);
    expect(adapter.requests, hasLength(2));
    adapter.requests[1].complete(_profileResponse('owner-a', 'Refreshed name'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('My draft'), findsOneWidget);
  });

  testWidgets(
    'late previous-owner profile cannot seed or save the new owner form',
    (tester) async {
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = _QueuedProfileAdapter();
      dio.httpClientAdapter = adapter;
      late final _SwitchableAuthController auth;
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(
            () => auth = _SwitchableAuthController(testUser(id: 'owner-a')),
          ),
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(client: dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      final profileSubscription = container.listen(
        profileFutureProvider('me'),
        (_, _) {},
      );
      addTearDown(profileSubscription.close);
      await _pumpPage(tester, container);
      await tester.pump(const Duration(seconds: 1));
      expect(adapter.requests, hasLength(1));

      expect(
        container.read(authControllerProvider).asData?.value?.id,
        'owner-a',
      );
      auth.switchTo(testUser(id: 'owner-b'));
      expect(
        container.read(authControllerProvider).asData?.value?.id,
        'owner-b',
      );
      await _pumpUntilRequestCount(tester, adapter, 2);
      expect(adapter.requests, hasLength(2));
      adapter.requests[1].complete(_profileResponse('owner-b', 'Owner B'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      adapter.requests[0].complete(
        _profileResponse('owner-a', 'Stale Owner A'),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Owner B'), findsOneWidget);
      expect(find.text('Stale Owner A'), findsNothing);
      await tester.tap(find.text('Salvar'));
      await _pumpUntilPatchCount(tester, adapter, 1);
      expect(adapter.patches, hasLength(1));
      final patch = adapter.patches.single;
      expect(
        patch,
        isA<Map<String, dynamic>>().having(
          (data) => data['displayName'],
          'displayName',
          'Owner B',
        ),
      );
    },
  );
}
