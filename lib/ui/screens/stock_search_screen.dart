import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/listing_filters.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import 'add_stock_screen.dart';
import 'stock_broadcast_screen.dart';
import 'stock_expenses_screen.dart';
import 'stock_gallery_screen.dart';
import '../widgets/stock_card.dart';
import 'stock_detail_screen.dart';
import '../widgets/list_filter_sheet.dart';

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  final CRMService _crmService = CRMService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<StockModel> _stock = [];
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 10;
  String _searchQuery = '';
  ListingFilters _filters = ListingFilters.empty;
  String? _errorMessage;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _fetchStock(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchStock({bool isRefresh = false}) async {
    if (_isLoadingMore || (_isInitialLoading && !isRefresh)) {
      return;
    }

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
        if (_stock.isEmpty) {
          _isInitialLoading = true;
        } else {
          _isRefreshing = true;
        }
      });
    } else if (!_hasMore) {
      return;
    } else {
      setState(() {
        _isLoadingMore = true;
        _errorMessage = null;
      });
    }

    final pageToLoad = isRefresh ? 1 : _currentPage;

    try {
      final result = await _crmService.fetchStock(
        page: pageToLoad,
        limit: _pageSize,
        search: _searchQuery,
        filters: _filters,
      );

      final fetchedItems = result['items'] as List<StockModel>;
      final hasNext = result['hasNextPage'] == true;

      if (!mounted) {
        return;
      }

      setState(() {
        if (isRefresh) {
          _stock = fetchedItems;
        } else {
          _stock.addAll(fetchedItems);
        }

        _isInitialLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        _hasMore = hasNext;
        _currentPage = hasNext ? pageToLoad + 1 : pageToLoad;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isInitialLoading = false;
        _isRefreshing = false;
        _isLoadingMore = false;
        if (_stock.isEmpty) {
          _errorMessage = 'Unable to load stock right now.';
        }
      });
      debugPrint("Stock pagination error: $e");
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }

    final triggerFetch =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240;

    if (triggerFetch) {
      _fetchStock();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }
      final trimmed = value.trim();
      if (trimmed == _searchQuery) {
        return;
      }
      _searchQuery = trimmed;
      _fetchStock(isRefresh: true);
    });
  }

  Future<void> _openStockDetail(StockModel stock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            StockDetailScreen(stockId: stock.id, initialStock: stock),
      ),
    );

    if (updated == true && mounted) {
      _fetchStock(isRefresh: true);
    }
  }

  Future<void> _openGalleryManager(StockModel stock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockGalleryScreen(
          stockId: stock.id,
          title: stock.displayTitle,
          registration: stock.displayRegistration,
        ),
      ),
    );

    if (updated == true && mounted) {
      _fetchStock(isRefresh: true);
    }
  }

  Future<void> _openExpensesManager(StockModel stock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StockExpensesScreen(
          stockId: stock.id,
          title: stock.displayTitle,
          registration: stock.displayRegistration,
        ),
      ),
    );
  }

  Future<void> _openBroadcastManager(StockModel stock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StockBroadcastScreen(
          stockId: stock.id,
          title: stock.displayTitle,
          registration: stock.displayRegistration,
        ),
      ),
    );

    if (updated == true && mounted) {
      _fetchStock(isRefresh: true);
    }
  }

  Future<void> _openStockOptionsSheet(StockModel stock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    // await showModalBottomSheet<void>(
    //   context: context,
    //   backgroundColor: Colors.transparent,
    //   builder: (context) => _StockOptionsSheet(
    //     stock: stock,
    //     onViewDetails: () {
    //       Navigator.pop(context);
    //       _openStockDetail(stock);
    //     },
    //     onManageGallery: () {
    //       Navigator.pop(context);
    //       _openGalleryManager(stock);
    //     },
    //     onBroadcast: () {
    //       Navigator.pop(context);
    //       _openBroadcastManager(stock);
    //     },
    //     onManageExpenses: () {
    //       Navigator.pop(context);
    //       _openExpensesManager(stock);
    //     },
    //   ),
    // );
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 1. Must be true to push up with keyboard
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        // 2. This pushes the content UP when the keyboard appears
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          // 3. Prevents content from hiding behind the system "Home" bar
          child: _StockOptionsSheet(
            stock: stock,
            onViewDetails: () {
              Navigator.pop(context);
              _openStockDetail(stock);
            },
            onManageGallery: () {
              Navigator.pop(context);
              _openGalleryManager(stock);
            },
            onBroadcast: () {
              Navigator.pop(context);
              _openBroadcastManager(stock);
            },
            onManageExpenses: () {
              Navigator.pop(context);
              _openExpensesManager(stock);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showListingFilterSheet(
      context,
      initialFilters: _filters,
      title: 'Stock Filters',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _filters = result);
    _fetchStock(isRefresh: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandYellow = Color(0xFFFACC14);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Stock",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: brandYellow,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {});
                      _onSearchChanged(value);
                    },
                    onSubmitted: (value) {
                      _searchDebounce?.cancel();
                      _searchQuery = value.trim();
                      _fetchStock(isRefresh: true);
                    },
                    decoration: InputDecoration(
                      hintText: "Search by reg, make, model, customer",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _fetchStock(isRefresh: true);
                                setState(() {});
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterButton(),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchStock(isRefresh: true),
              color: Colors.black,
              backgroundColor: brandYellow,
              child: _isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandYellow),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _stock.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          _stock.length +
                          1 +
                          (_isLoadingMore || _hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _stock.length) {
                          return InventoryCard(
                            stock: _stock[index],
                            onTap: () => _openStockDetail(_stock[index]),
                            onShowOptions: () =>
                                _openStockOptionsSheet(_stock[index]),
                          );
                        }

                        if (index == _stock.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_stock.length} stock items loaded",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (_isRefreshing)
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: brandYellow,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }

                        return Visibility(
                          visible: _isLoadingMore,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: brandYellow,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        foregroundColor: const Color(0xFFFACC14),
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddStockScreen()),
          );
          if (created == true && mounted) {
            _fetchStock(isRefresh: true);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Icon(Icons.wifi_off_rounded, size: 46, color: Colors.grey),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () => _fetchStock(isRefresh: true),
            child: const Text("Try Again"),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Text(
            _searchQuery.isEmpty
                ? "No stock found."
                : "No stock matches \"$_searchQuery\".",
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
          style: IconButton.styleFrom(
            backgroundColor: _filters.hasActiveFilters
                ? const Color(0xFFFACC14)
                : Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_filters.activeFilterCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _filters.activeFilterCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StockOptionsSheet extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onViewDetails;
  final VoidCallback onManageGallery;
  final VoidCallback onBroadcast;
  final VoidCallback onManageExpenses;

  const _StockOptionsSheet({
    required this.stock,
    required this.onViewDetails,
    required this.onManageGallery,
    required this.onBroadcast,
    required this.onManageExpenses,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                stock.displayTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                stock.displayRegistration,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              _OptionTile(
                icon: Icons.visibility_outlined,
                title: 'View Details',
                subtitle: 'Open vehicle information and gallery summary',
                onTap: onViewDetails,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.photo_library_outlined,
                title: 'Manage Gallery',
                subtitle: 'Upload, delete, feature, and reorder images',
                onTap: onManageGallery,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.campaign_outlined,
                title: 'Broadcast',
                subtitle: 'Push stock live and sync status or price',
                onTap: onBroadcast,
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.shopping_cart_checkout_outlined,
                title: 'Expenses',
                subtitle: 'Track reconditioning and prep costs',
                onTap: onManageExpenses,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F7F2),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC14).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.black),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
