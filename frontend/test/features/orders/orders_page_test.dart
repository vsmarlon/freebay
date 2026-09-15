import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/orders/data/entities/order_entity.dart';
import 'package:freebay/features/orders/data/repositories/order_repository.dart';
import 'package:freebay/features/orders/data/services/order_service.dart';
import 'package:freebay/features/orders/presentation/pages/orders_page.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/shared/either/either.dart';
import 'package:freebay/shared/models/cursor_page.dart';

class _PageRepository extends OrderRepository {
  final responses = <Future<Either<Failure, CursorPage<OrderEntity>>>>[];
  final calls = <({String? cursor, String? status})>[];

  _PageRepository() : super(OrderService());

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMyPurchases({
    String? cursor,
    int limit = 20,
    String? status,
  }) async => const Right(CursorPage(items: [], hasMore: false));

  @override
  Future<Either<Failure, CursorPage<OrderEntity>>> getMySales({
    String? cursor,
    int limit = 20,
    String? status,
  }) {
    calls.add((cursor: cursor, status: status));
    return responses.removeAt(0);
  }
}

OrderEntity _order(String id) => OrderEntity(
  id: id,
  buyerId: 'buyer-1',
  sellerId: 'seller-1',
  productId: 'product-1',
  amount: 1000,
  platformFee: 100,
  sellerAmount: 900,
  status: OrderStatus.shipped,
  escrowStatus: EscrowStatus.held,
  createdAt: DateTime(2026, 9, 12),
);

Future<void> _pumpStatusFilters(
  WidgetTester tester, {
  OrderStatus? selected,
  required ValueChanged<OrderStatus?> onChanged,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SalesStatusFilters(selected: selected, onChanged: onChanged),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('exposes accessible All and every seller status control', (
    tester,
  ) async {
    await _pumpStatusFilters(tester, onChanged: (_) {});

    final all = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics && widget.properties.label == 'Todos os status',
    );
    expect(all, findsOneWidget);
    for (final status in OrderStatus.values) {
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics && widget.properties.label == status.label,
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'status action uses the provider and keeps products out of Vendas',
    (tester) async {
      OrderStatus? selected;

      await _pumpStatusFilters(
        tester,
        onChanged: (status) => selected = status,
      );
      await tester.tap(find.text('ENVIADO'));
      await tester.pump();

      expect(selected, OrderStatus.shipped);
      expect(find.text('MEUS PRODUTOS'), findsNothing);
    },
  );

  testWidgets(
    'renders Vendas surface empty state and keeps products separate',
    (tester) async {
      final emptyRepository = _PageRepository();
      emptyRepository.responses.add(
        Future.value(const Right(CursorPage(items: [], hasMore: false))),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(emptyRepository),
          ],
          child: const MaterialApp(home: OrdersTab(isSeller: true)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('NENHUMA VENDA'), findsOneWidget);

      emptyRepository.responses.add(
        Future.value(const Right(CursorPage(items: [], hasMore: false))),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            orderRepositoryProvider.overrideWithValue(emptyRepository),
          ],
          child: const MaterialApp(home: OrdersPage()),
        ),
      );
      expect(find.text('VENDAS'), findsOneWidget);
      expect(find.text('MEUS PRODUTOS'), findsNothing);
    },
  );

  testWidgets(
    'shows loading more and retries the append with the preserved cursor',
    (tester) async {
      final more = Completer<Either<Failure, CursorPage<OrderEntity>>>();
      final repository = _PageRepository()
        ..responses.add(
          Future.value(
            Right(
              CursorPage(
                items: [_order('order-1')],
                hasMore: true,
                nextCursor: 'cursor-1',
              ),
            ),
          ),
        )
        ..responses.add(more.future)
        ..responses.add(
          Future.value(const Right(CursorPage(items: [], hasMore: false))),
        );
      final container = ProviderContainer(
        overrides: [orderRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OrdersTab(isSeller: true)),
        ),
      );
      await tester.pumpAndSettle();

      final loading = container.read(salesListProvider.notifier).loadMore();
      await tester.pump();
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump();
      expect(find.byType(ShimmerBlock), findsOneWidget);

      more.complete(const Left(ServerFailure('append failed')));
      await loading;
      await tester.pumpAndSettle();
      expect(find.text('TENTAR NOVAMENTE'), findsOneWidget);
      expect(find.text('Item #order-1'), findsOneWidget);

      await tester.tap(find.text('TENTAR NOVAMENTE'));
      await tester.pumpAndSettle();
      expect(repository.calls.last.cursor, 'cursor-1');
      expect(find.text('FIM DA LISTA'), findsOneWidget);
    },
  );
}
