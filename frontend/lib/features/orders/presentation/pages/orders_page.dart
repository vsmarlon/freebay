import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:freebay/core/ui.dart';
import 'package:freebay/features/orders/presentation/providers/order_providers.dart';
import 'package:freebay/features/orders/presentation/pages/orders_tab.dart';
import 'package:freebay/shared/l10n/app_localizations_context.dart';

export 'orders_tab.dart';
export '../widgets/sales_status_filters.dart';

class OrdersPage extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const OrdersPage({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int? _requestedTabIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_loadVisibleTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVisibleTab();
    });
  }

  void _loadVisibleTab() {
    if (_tabController.indexIsChanging) return;
    if (_requestedTabIndex == _tabController.index) return;
    _requestedTabIndex = _tabController.index;
    if (_tabController.index == 0) {
      ref.read(purchasesListProvider.notifier).loadPurchases();
    } else {
      ref.read(salesListProvider.notifier).loadSales();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_loadVisibleTab);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = l10n(context);
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              text: strings.ordersMyOrders,
              leading: BrutalistIconButton(
                icon: Icons.arrow_back,
                semanticLabel: strings.accessibilityBack,
                onTap: () => context.pop(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.borderColor, width: 2),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryContainer,
                indicatorWeight: 3,
                labelColor: context.textPrimary,
                unselectedLabelColor: context.textSecondary,
                labelStyle: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
                tabs: [
                  Tab(text: strings.ordersPurchasesTab),
                  Tab(text: strings.ordersSalesTab),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  OrdersTab(isSeller: false),
                  OrdersTab(isSeller: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
