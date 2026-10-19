import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/core/router/app_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/features/auth/data/repositories/auth_repository.dart';
import 'package:freebay/features/auth/data/entities/user_entity.dart';
import 'package:freebay/features/profile/data/repositories/profile_repository.dart';
import 'package:freebay/features/profile/presentation/controllers/profile_controller.dart';
import 'package:freebay/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:freebay/features/chat/presentation/providers/chat_socket_provider.dart';
import 'package:freebay/shared/services/chat_socket_service.dart';
import 'package:freebay/shared/services/notification_socket_service.dart';
import 'package:freebay/shared/l10n/generated/app_localizations.dart';
import 'package:freebay/shared/services/storage_service.dart';
import 'package:freebay/shared/services/http_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

class _EditProfileRouterAdapter implements HttpClientAdapter {
  _EditProfileRouterAdapter({
    this.patchStatus = 200,
    this.challengeExpiresIn = 3,
    this.challengeResponse,
  });

  final int patchStatus;
  final int challengeExpiresIn;
  final Completer<ResponseBody>? challengeResponse;
  final requests = <String>[];
  final patches = <Map<String, dynamic>>[];
  final patchStatuses = <int>[];
  Map<String, Object?> user = {
    'id': 'owner-a',
    'displayName': 'Ada Example',
    'username': 'ada_example',
    'bio': 'Original bio',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');
    if (options.method == 'POST' &&
        options.path == '/users/me/profile-verification') {
      final response = ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {'expiresIn': challengeExpiresIn, 'resendAfter': 60},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
      return challengeResponse?.future ?? Future.value(response);
    }
    if (options.method == 'PATCH' && options.path == '/users/me') {
      final requestData = options.data;
      if (requestData is Map<String, dynamic>) patches.add(requestData);
      final status = patchStatuses.isEmpty
          ? patchStatus
          : patchStatuses.removeAt(0);
      if (status != 200) {
        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': 'Invalid verification code',
          }),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      }
      if (requestData is Map<String, dynamic>) {
        user = {...user, ...requestData};
      }
    }
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': user}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _NoopChatSocketService extends ChatSocketService {
  @override
  Future<void> connect() async {}

  @override
  void disconnect() {}

  @override
  void dispose() {}
}

class _NoopNotificationSocketService extends NotificationSocketService {
  @override
  Future<void> connect() async {}

  @override
  void disconnect() {}

  @override
  void dispose() {}
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
    'changed CPF requests a code before PATCHing document with proof',
    (tester) async {
      final adapter = _EditProfileRouterAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = adapter;
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
      await _pumpPage(tester, container);
      await tester.pump(const Duration(seconds: 1));

      await tester.enterText(find.byType(TextFormField).last, '52998224725');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(adapter.requests, contains('POST /users/me/profile-verification'));
      expect(adapter.patches, isEmpty);
      expect(
        find.byKey(const ValueKey('profileVerificationCodeField')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('profileVerificationCodeField')),
        '123456',
      );
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();
      expect(adapter.patches.single, containsPair('cpf', '52998224725'));
      expect(
        adapter.patches.single,
        containsPair('profileVerificationCode', '123456'),
      );
    },
  );

  testWidgets('server rejects invalid proof without updating auth or popping', (
    tester,
  ) async {
    final adapter = _EditProfileRouterAdapter(patchStatus: 400);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
    final auth = _SwitchableAuthController(testUser(id: 'owner-a'));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pumpPage(tester, container);
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextFormField).last, '52998224725');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      '123456',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(adapter.patches, hasLength(1));
    expect(adapter.patches.single['profileVerificationCode'], '123456');
    expect(auth.state.value?.id, 'owner-a');
    expect(find.byType(EditProfilePage), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      findsOneWidget,
    );
    expect(
      adapter.requests.where((request) => request == 'PATCH /users/me'),
      hasLength(1),
    );
  });

  testWidgets('wrong verification code can retry the live challenge', (
    tester,
  ) async {
    final adapter = _EditProfileRouterAdapter(challengeExpiresIn: 600)
      ..patchStatuses.addAll([400, 200]);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
    final auth = _SwitchableAuthController(testUser(id: 'owner-a'));
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => auth),
        profileRepositoryProvider.overrideWithValue(
          ProfileRepository(client: dio),
        ),
      ],
    );
    addTearDown(container.dispose);
    await _pumpPage(tester, container);
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextFormField).last, '52998224725');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      '111111',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      findsOneWidget,
    );
    expect(auth.state.value?.id, 'owner-a');
    expect(find.byType(EditProfilePage), findsOneWidget);
    ScaffoldMessenger.of(
      tester.element(find.byType(EditProfilePage)),
    ).hideCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      '123456',
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(
      adapter.requests.where(
        (request) => request == 'POST /users/me/profile-verification',
      ),
      hasLength(1),
    );
    expect(adapter.patches, hasLength(2));
    expect(adapter.patches.map((patch) => patch['profileVerificationCode']), [
      '111111',
      '123456',
    ]);
    expect(auth.state.value?.id, 'owner-a');
    expect(find.byType(EditProfilePage), findsNothing);
  });

  testWidgets('changing CPF clears the code proof and requests a fresh one', (
    tester,
  ) async {
    final adapter = _EditProfileRouterAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = adapter;
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
    await _pumpPage(tester, container);
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextFormField).last, '52998224725');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      '123456',
    );

    final cpfField = tester
        .widgetList<AppTextField>(find.byType(AppTextField))
        .singleWhere(
          (field) =>
              field.controller?.text
                  .replaceAll(RegExp(r'\D'), '')
                  .contains('529982') ==
              true,
        );
    await tester.enterText(
      find.descendant(
        of: find.byWidget(cpfField),
        matching: find.byType(TextFormField),
      ),
      '11144477735',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('profileVerificationCodeField')),
      findsNothing,
    );
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(
      adapter.requests.where(
        (request) => request == 'POST /users/me/profile-verification',
      ),
      hasLength(2),
    );
    expect(adapter.patches, isEmpty);
  });

  testWidgets(
    'late challenge response after account switch does not authorize CPF',
    (tester) async {
      final challenge = Completer<ResponseBody>();
      final adapter = _EditProfileRouterAdapter(challengeResponse: challenge);
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = adapter;
      final auth = _SwitchableAuthController(testUser(id: 'owner-a'));
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => auth),
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(client: dio),
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pumpPage(tester, container);
      await tester.pump(const Duration(seconds: 1));
      await tester.enterText(find.byType(TextFormField).last, '52998224725');
      await tester.tap(find.text('Salvar'));
      await tester.pump();
      auth.switchTo(testUser(id: 'owner-b'));
      challenge.complete(
        ResponseBody.fromString(
          jsonEncode({
            'success': true,
            'data': {'expiresIn': 600, 'resendAfter': 60},
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profileVerificationCodeField')),
        findsNothing,
      );
      expect(adapter.patches, isEmpty);
    },
  );

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

  testWidgets('save stays reachable above the keyboard at large text scale', (
    tester,
  ) async {
    tester.view.viewInsets = const FakeViewPadding(bottom: 900);
    addTearDown(tester.view.resetViewInsets);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
      ..httpClientAdapter = _ProfileAdapter();

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
        child: MaterialApp(
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const EditProfilePage(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    final save = find.text('Salvar');
    expect(save, findsOneWidget);
    expect(tester.getRect(save).bottom, lessThanOrEqualTo(300));
    expect(
      tester.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'successful profile save updates production auth state and pops the edit route',
    (tester) async {
      const owner = 'owner-a';
      SharedPreferences.setMockInitialValues({
        'has_seen_onboarding': true,
        'remember_me': true,
        'welcome_setup_done_$owner': true,
      });
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'access'});
      await tester.runAsync(StorageService.init);
      final adapter = _EditProfileRouterAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'))
        ..httpClientAdapter = adapter;
      HttpClient.instance.httpClientAdapter = adapter;
      HttpClient.establishSession();
      HttpClient.instance.options.headers.remove('Authorization');
      final container = ProviderContainer(
        overrides: [
          profileRepositoryProvider.overrideWithValue(
            ProfileRepository(client: dio),
          ),
          authRepositoryProvider.overrideWithValue(
            AuthRepository(client: HttpClient.instance),
          ),
          chatSocketServiceProvider.overrideWithValue(_NoopChatSocketService()),
          notificationSocketServiceProvider.overrideWithValue(
            _NoopNotificationSocketService(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final authSubscription = container.listen(
        authControllerProvider,
        (_, _) {},
      );
      addTearDown(authSubscription.close);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: appRouter,
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(container.read(isInitialAuthLoadingProvider), isFalse);
      expect(container.read(authControllerProvider).value?.id, owner);
      await tester.pumpAndSettle();
      appRouter.go(AppRoutes.profile);
      await tester.pumpAndSettle();
      appRouter.push<void>(AppRoutes.profileEdit);
      await tester.pumpAndSettle();
      expect(find.byType(EditProfilePage), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Updated name');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(
        container.read(authControllerProvider).value?.displayName,
        'Updated name',
      );
      expect(
        appRouter.routeInformationProvider.value.uri.path,
        AppRoutes.profile,
      );
      expect(find.byType(EditProfilePage), findsNothing);
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
