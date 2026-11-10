import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/orders/presentation/pages/orders_page.dart';
import 'package:freebay/features/orders/presentation/pages/order_detail_page.dart';
import 'package:freebay/features/dispute/presentation/pages/dispute_list_page.dart';
import 'package:freebay/features/dispute/presentation/pages/create_dispute_page.dart';
import 'package:freebay/features/dispute/presentation/pages/dispute_detail_page.dart';

final List<RouteBase> orderRoutes = [
  appCupertinoRoute(AppRoutes.orders, (context, state) => const OrdersPage()),
  appCupertinoRoute(
    AppRoutes.orderDetail,
    (context, state) =>
        OrderDetailPage(orderId: state.pathParameters['orderId']!),
  ),
  appCupertinoRoute(
    AppRoutes.disputes,
    (context, state) => const DisputeListPage(),
  ),
  appCupertinoRoute(
    AppRoutes.createDispute,
    (context, state) =>
        CreateDisputePage(orderId: state.pathParameters['orderId']!),
  ),
  appCupertinoRoute(
    AppRoutes.disputeDetail,
    (context, state) =>
        DisputeDetailPage(disputeId: state.pathParameters['disputeId']!),
  ),
];
