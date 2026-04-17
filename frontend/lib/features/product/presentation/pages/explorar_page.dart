import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../product/data/entities/category_entity.dart';
import '../../../product/domain/usecases/get_products_usecase.dart';
import '../../../product/presentation/controllers/product_controller.dart';
import '../../../social/presentation/providers/user_search_provider.dart';
import '../../../social/presentation/widgets/user_search_list.dart';

class ExplorarPage extends ConsumerStatefulWidget {
  const ExplorarPage({super.key});

  @override
  ConsumerState<ExplorarPage> createState() => _ExplorarPageState();
}

class _ExplorarPageState extends ConsumerState<ExplorarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _showFilters = false;
  Timer? _debounceTimer;
  final Map<String, bool> _followingMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchDebounced(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_tabController.index == 1) {
        ref
            .read(userSearchProvider.notifier)
            .search(query: query, refresh: true);
      } else {
        ref.read(searchQueryProvider.notifier).state = query;
      }
    });
  }

  void _onSearch() {
    _debounceTimer?.cancel();
    final query = _searchController.text;
    if (_tabController.index == 1) {
      ref.read(userSearchProvider.notifier).search(query: query, refresh: true);
    } else {
      ref.read(searchQueryProvider.notifier).state = query;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Explorar',
          style: TextStyle(
            color: isDark ? AppColors.white : AppColors.primaryPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.white : AppColors.primaryPurple,
          unselectedLabelColor:
              isDark ? AppColors.mediumGray : AppColors.mediumGray,
          indicatorColor: AppColors.primaryPurple,
          tabs: const [
            Tab(text: 'Produtos'),
            Tab(text: 'Pessoas'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: isDark ? AppColors.white : AppColors.primaryPurple,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add_box_outlined,
              color: isDark
                  ? AppColors.primaryPurpleLight
                  : AppColors.primaryPurpleDark,
            ),
            onPressed: () => context.push('/products/create'),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tabController.index == 1
                    ? 'Buscar pessoas...'
                    : 'Buscar produtos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
              onChanged: _onSearchDebounced,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProdutosTab(isDark, selectedCategory, categoriesAsync),
                _buildPessoasTab(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdutosTab(bool isDark, String? selectedCategory,
      AsyncValue<List<CategoryEntity>> categoriesAsync) {
    final searchQuery = ref.watch(searchQueryProvider);

    final productsAsync = ref.watch(productsFeedProvider(
      GetProductsParams(
        search: searchQuery.isEmpty ? null : searchQuery,
        category: selectedCategory,
      ),
    ));

    return Column(
      children: [
        if (_showFilters)
          categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma categoria disponível'),
                );
              }
              return _buildCategoryTree(categories, selectedCategory, isDark);
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro ao carregar categorias: $err'),
            ),
          ),
        Expanded(
          child: productsAsync.when(
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: isDark
                            ? AppColors.mediumGray
                            : AppColors.mediumGray,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum produto encontrado.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.mediumGray
                              : AppColors.mediumGray,
                          fontSize: 16,
                        ),
                      ),
                      if (searchQuery.isNotEmpty ||
                          selectedCategory != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                            ref.read(selectedCategoryProvider.notifier).state =
                                null;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            color: isDark
                                ? AppColors.surfaceContainerDark
                                : AppColors.surfaceContainerHighest,
                            child: Text(
                              'Limpar filtros',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.white : AppColors.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => ref.refresh(productsFeedProvider(
                  GetProductsParams(
                    search: searchQuery.isEmpty ? null : searchQuery,
                    category: selectedCategory,
                  ),
                ).future),
                color: AppColors.primaryPurple,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return AppCard(
                      imageUrl: product.imageUrl,
                      title: product.title,
                      priceInCents: product.price,
                      variant: AppCardVariant.compact,
                      onTap: () => context.push('/products/${product.id}'),
                    );
                  },
                ),
              );
            },
            loading: () => GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const AppCard.skeleton(),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar\nerro: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? AppColors.white : AppColors.darkGray),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => ref.invalidate(productsFeedProvider(
                      GetProductsParams(
                        search: searchQuery.isEmpty ? null : searchQuery,
                        category: selectedCategory,
                      ),
                    )),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: const BoxDecoration(
                        gradient: AppColors.brutalistGradient,
                      ),
                      child: const Center(
                        child: Text(
                          'Tentar novamente',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: AppColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPessoasTab(bool isDark) {
    final searchState = ref.watch(userSearchProvider);
    final searchQuery = _searchController.text;

    if (searchQuery.isEmpty && searchState.users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Busque por pessoas...',
              style: TextStyle(
                color: isDark ? AppColors.mediumGray : AppColors.mediumGray,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return UserSearchList(
      users: searchState.users,
      isLoading: searchState.isLoading,
      onLoadMore: () {
        if (searchState.hasMore && !searchState.isLoading) {
          ref.read(userSearchProvider.notifier).search(query: searchQuery);
        }
      },
      onFollow: (userId) async {
        await ref.read(socialRepositoryProvider).followUser(userId);
        setState(() {
          _followingMap[userId] = true;
        });
      },
      onUnfollow: (userId) async {
        await ref.read(socialRepositoryProvider).unfollowUser(userId);
        setState(() {
          _followingMap[userId] = false;
        });
      },
    );
  }

  Widget _buildCategoryTree(
      List<CategoryEntity> categories, String? selectedCategory, bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.mediumGray.withValues(alpha: 0.2)
                : AppColors.lightGray,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: selectedCategory == null,
                onSelected: (_) {
                  ref.read(selectedCategoryProvider.notifier).state = null;
                },
                selectedColor: AppColors.primaryPurple.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primaryPurple,
              ),
              ..._flattenCategories(categories),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _flattenCategories(List<CategoryEntity> categories,
      {int indent = 0}) {
    final widgets = <Widget>[];

    for (final cat in categories) {
      final isSelected = ref.watch(selectedCategoryProvider) == cat.id;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(left: indent * 12.0),
          child: FilterChip(
            label: Text(cat.name),
            selected: isSelected,
            onSelected: (_) {
              ref.read(selectedCategoryProvider.notifier).state =
                  isSelected ? null : cat.id;
            },
            selectedColor: AppColors.primaryPurple.withValues(alpha: 0.2),
            checkmarkColor: AppColors.primaryPurple,
          ),
        ),
      );

      if (cat.children.isNotEmpty) {
        widgets.addAll(_flattenCategories(cat.children, indent: indent + 1));
      }
    }

    return widgets;
  }
}
