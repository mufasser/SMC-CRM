import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/listing_filters.dart';
import '../../data/models/offer_model.dart';
import '../../data/services/crm_service.dart';
import '../widgets/offer_card.dart';
import 'offer_detail_screen.dart';
import '../widgets/list_filter_sheet.dart';

class AcceptedOffersScreen extends StatefulWidget {
  const AcceptedOffersScreen({super.key});

  @override
  State<AcceptedOffersScreen> createState() => _AcceptedOffersScreenState();
}

class _AcceptedOffersScreenState extends State<AcceptedOffersScreen> {
  final CRMService _crmService = CRMService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<OfferModel> _offers = [];
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
    _fetchOffers(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchOffers({bool isRefresh = false}) async {
    if (_isLoadingMore || (_isInitialLoading && !isRefresh)) {
      return;
    }

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
        if (_offers.isEmpty) {
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
      final result = await _crmService.fetchOffers(
        page: pageToLoad,
        limit: _pageSize,
        search: _searchQuery,
        filters: _filters,
      );

      final fetchedItems = result['items'] as List<OfferModel>;
      final hasNext = result['hasNextPage'] == true;

      if (!mounted) {
        return;
      }

      setState(() {
        if (isRefresh) {
          _offers = fetchedItems;
        } else {
          _offers.addAll(fetchedItems);
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
        if (_offers.isEmpty) {
          _errorMessage = 'Unable to load offers right now.';
        }
      });
      debugPrint("Offers pagination error: $e");
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
      _fetchOffers();
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
      _fetchOffers(isRefresh: true);
    });
  }

  void _openOfferDetail(OfferModel offer) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OfferDetailScreen(offer: offer)),
    );
  }

  Future<void> _openFilters() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showListingFilterSheet(
      context,
      initialFilters: _filters,
      title: 'Offer Filters',
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() => _filters = result);
    _fetchOffers(isRefresh: true);
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
          "Offers",
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
                      _fetchOffers(isRefresh: true);
                    },
                    decoration: InputDecoration(
                      hintText: "Search by customer, reg, make, model",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery = '';
                                _fetchOffers(isRefresh: true);
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
              onRefresh: () => _fetchOffers(isRefresh: true),
              color: Colors.black,
              backgroundColor: brandYellow,
              child: _isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandYellow),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _offers.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          _offers.length + 1 + (_isLoadingMore || _hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _offers.length) {
                          return OfferCard(
                            offer: _offers[index],
                            onTap: () => _openOfferDetail(_offers[index]),
                          );
                        }

                        if (index == _offers.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_offers.length} offers loaded",
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
            onPressed: () => _fetchOffers(isRefresh: true),
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
          child: Column(
            children: [
              Icon(Icons.handshake_outlined, size: 64, color: Colors.grey[200]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? "No offers found."
                    : "No offers match \"$_searchQuery\".",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
