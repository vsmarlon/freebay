import 'package:go_router/go_router.dart';
import 'package:freebay/core/router/app_routes.dart';
import 'package:freebay/core/router/route_helpers.dart';
import 'package:freebay/features/product/presentation/pages/create_product_page.dart';
import 'package:freebay/features/product/presentation/pages/product_detail_page.dart';
import 'package:freebay/features/product/presentation/pages/edit_product_page.dart';
import 'package:freebay/features/product/presentation/pages/cart_page.dart';
import 'package:freebay/features/cart/presentation/pages/cart_checkout_page.dart';

final List<RouteBase> productRoutes = [
  appCupertinoRoute(
    AppRoutes.createProduct,
    (context, state) => const CreateProductPage(),
  ),
  appCupertinoRoute(
    AppRoutes.productDetail,
    (context, state) =>
        ProductDetailPage(productId: state.pathParameters['id']!),
    routes: [
      appCupertinoRoute(
        AppRoutes.editProduct,
        (context, state) =>
            EditProductPage(productId: state.pathParameters['id']!),
      ),
    ],
  ),
  appCupertinoRoute(AppRoutes.cart, (context, state) => const CartPage()),
  appCupertinoRoute(
    AppRoutes.checkoutCart,
    (context, state) => const CartCheckoutPage(),
  ),
];
