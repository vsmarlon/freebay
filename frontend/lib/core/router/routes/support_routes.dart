import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/help/presentation/pages/faq_page.dart';

final List<RouteBase> supportRoutes = [
  appCupertinoRoute(AppRoutes.faq, (context, state) => const FaqPage()),
];
