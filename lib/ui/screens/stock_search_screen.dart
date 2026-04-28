import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/crm_service.dart';
import 'add_stock_screen.dart';
import '../widgets/stock_card.dart';
import 'stock_detail_screen.dart';

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

  void _openStockDetail(StockModel stock) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StockDetailScreen(stockId: stock.id, initialStock: stock),
      ),
    );
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
                      itemCount: _stock.length + 1 + (_isLoadingMore || _hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _stock.length) {
                          return InventoryCard(
                            stock: _stock[index],
                            onTap: () => _openStockDetail(_stock[index]),
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
}
