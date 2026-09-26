import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freebay/features/wallet/data/entities/wallet_entity.dart';
import 'package:freebay/features/wallet/data/entities/connect_status_entity.dart';
import 'package:freebay/features/wallet/data/entities/wallet_transaction_entity.dart';
import 'package:freebay/features/wallet/data/repositories/wallet_repository.dart';
import 'package:freebay/features/wallet/presentation/controllers/wallet_controller.dart'
    hide ConnectStatus;
import 'package:freebay/features/wallet/presentation/pages/wallet_page.dart';
import 'package:freebay/features/auth/presentation/controllers/auth_controller.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/errors/failures/failures.dart';
import 'package:freebay/shared/models/cursor_page.dart';
import '../../support/auth_test_doubles.dart';
import '../../support/test_users.dart';

class _WalletRepository extends WalletRepository {
  final initial =
      Completer<Either<Failure, CursorPage<WalletTransactionEntity>>>();
  final loadMore =
      Completer<Either<Failure, CursorPage<WalletTransactionEntity>>>();
  final refresh =
      Completer<Either<Failure, CursorPage<WalletTransactionEntity>>>();
  int _initialLoads = 0;
  final walletLoads = <Completer<Either<Failure, WalletEntity>>>[];

  @override
  Future<Either<Failure, WalletEntity>> getWallet() {
    final load = Completer<Either<Failure, WalletEntity>>();
    walletLoads.add(load);
    return load.future;
  }

  @override
  Future<Either<Failure, CursorPage<WalletTransactionEntity>>> getTransactions({
    String? cursor,
    int? limit,
  }) {
    if (cursor != null) return loadMore.future;
    _initialLoads++;
    return _initialLoads == 1 ? initial.future : refresh.future;
  }
}

class _RenderingWalletRepository extends _WalletRepository {
  _RenderingWalletRepository({
    this.status = ConnectStatus.onboardingRequired,
    this.requirementsDue = const [],
  });

  final ConnectStatus status;
  final List<String> requirementsDue;

  @override
  Future<Either<Failure, WalletEntity>> getWallet() async =>
      const Right(WalletEntity());

  @override
  Future<Either<Failure, CursorPage<WalletTransactionEntity>>> getTransactions({
    String? cursor,
    int? limit,
  }) async => const Right(
    CursorPage<WalletTransactionEntity>(items: [], hasMore: false),
  );

  @override
  Future<Either<Failure, ConnectStatusEntity>> getConnectStatus() async =>
      Right(
        ConnectStatusEntity(status: status, requirementsDue: requirementsDue),
      );
}

void main() {
  test(
    'refresh superseding loadMore clears the pagination loading state',
    () async {
      final repository = _WalletRepository();
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(walletHistoryProvider.notifier);

      final initialLoad = notifier.load('user-1');
      repository.initial.complete(
        const Right(
          CursorPage<WalletTransactionEntity>(
            items: [],
            hasMore: true,
            nextCursor: 'next',
          ),
        ),
      );
      await initialLoad;

      final paginationLoad = notifier.loadMore();
      final refreshLoad = notifier.load('user-1');
      repository.refresh.complete(
        const Right(
          CursorPage<WalletTransactionEntity>(items: [], hasMore: false),
        ),
      );
      await refreshLoad;
      repository.loadMore.complete(
        const Right(
          CursorPage<WalletTransactionEntity>(items: [], hasMore: false),
        ),
      );
      await paginationLoad;

      expect(container.read(walletHistoryProvider).isLoadingMore, isFalse);
    },
  );

  test(
    'keeps the newest account wallet when an older request finishes later',
    () async {
      final repository = _WalletRepository();
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(walletProvider.notifier);

      final userALoad = notifier.loadWallet('user-a');
      final userBLoad = notifier.loadWallet('user-b');
      expect(container.read(walletProvider).isLoading, isTrue);

      repository.walletLoads[1].complete(
        const Right(WalletEntity(availableBalance: 200, pendingBalance: 20)),
      );
      await userBLoad;
      repository.walletLoads[0].complete(
        const Right(WalletEntity(availableBalance: 100, pendingBalance: 10)),
      );
      await userALoad;

      expect(container.read(walletProvider).value?.availableBalance, 200);
    },
  );

  test(
    'exposes failure and allows a retry to replace it with zero balance',
    () async {
      final repository = _WalletRepository();
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(walletProvider.notifier);

      final failedLoad = notifier.loadWallet('user-a');
      repository.walletLoads[0].complete(
        const Left(ServerFailure('wallet failed')),
      );
      await failedLoad;
      expect(container.read(walletProvider).hasError, isTrue);

      final retry = notifier.loadWallet('user-a');
      repository.walletLoads[1].complete(const Right(WalletEntity()));
      await retry;

      expect(container.read(walletProvider).value, const WalletEntity());
    },
  );

  test(
    'reset clears wallet state and ignores an in-flight logout response',
    () async {
      final repository = _WalletRepository();
      final container = ProviderContainer(
        overrides: [walletRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final notifier = container.read(walletProvider.notifier);

      final load = notifier.loadWallet('user-a');
      notifier.reset();
      repository.walletLoads[0].complete(
        const Right(WalletEntity(availableBalance: 100)),
      );
      await load;

      expect(container.read(walletProvider).value, isNull);
      expect(container.read(walletProvider).isLoading, isTrue);
    },
  );

  testWidgets('renders a deterministic zero balance and empty history', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            () => TestAuthController(testUser(id: 'user-a')),
          ),
          walletRepositoryProvider.overrideWithValue(
            _RenderingWalletRepository(),
          ),
        ],
        child: const MaterialApp(home: WalletPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('R\$ 0,00'), findsWidgets);
    expect(find.text('SEM TRANSAÇÕES'), findsOneWidget);
  });

  testWidgets('renders an actionable action for every Connect status', (
    tester,
  ) async {
    const cases = [
      (ConnectStatus.onboardingRequired, 'CONFIGURAR RECEBIMENTOS'),
      (ConnectStatus.requirementsDue, 'CORRIGIR CADASTRO NO STRIPE'),
      (ConnectStatus.restricted, 'CORRIGIR CADASTRO NO STRIPE'),
      (ConnectStatus.transferReady, 'ABRIR PAINEL DE PAGAMENTOS'),
    ];

    for (final testCase in cases) {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              () => TestAuthController(testUser(id: 'user-a')),
            ),
            walletRepositoryProvider.overrideWithValue(
              _RenderingWalletRepository(
                status: testCase.$1,
                requirementsDue: testCase.$1 == ConnectStatus.requirementsDue
                    ? const ['tax_id']
                    : const [],
              ),
            ),
          ],
          child: MaterialApp(home: WalletPage(key: ValueKey(testCase.$1))),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(find.text(testCase.$2), findsOneWidget);
      if (testCase.$1 == ConnectStatus.requirementsDue) {
        expect(find.text('PENDÊNCIAS: tax_id'), findsOneWidget);
      }
    }
  });
}
