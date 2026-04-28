import 'dart:async';

import 'package:flutter/material.dart';
import '../../data/models/lead_model.dart';
import '../../data/services/crm_service.dart';
import 'lead_detail_screen.dart';
import '../widgets/car_card.dart';

class LeadsListScreen extends StatefulWidget {
  const LeadsListScreen({super.key});

  @override
  State<LeadsListScreen> createState() => _LeadsListScreenState();
}

class _LeadsListScreenState extends State<LeadsListScreen> {
  final CRMService _crmService = CRMService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<LeadModel> _allLeads = [];
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
    _fetchLeads(isRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  Future<void> _fetchLeads({bool isRefresh = false}) async {
    if (_isLoadingMore || (_isInitialLoading && !isRefresh)) {
      return;
    }

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _errorMessage = null;
        if (_allLeads.isEmpty) {
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
      final result = await _crmService.fetchData(
        endpoint: '/leads',
        page: pageToLoad,
        limit: _pageSize,
        search: _searchQuery,
      );

      final fetchedItems = (result['items'] as List<LeadModel>);
      final hasNext = result['hasNextPage'] == true;

      if (!mounted) {
        return;
      }
      setState(() {
        if (isRefresh) {
          _allLeads = fetchedItems;
        } else {
          _allLeads.addAll(fetchedItems);
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
        if (_allLeads.isEmpty) {
          _errorMessage = 'Unable to load leads right now.';
        }
      });
      debugPrint("Pagination Error: $e");
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
      _fetchLeads();
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
      _fetchLeads(isRefresh: true);
    });
  }

  void _openLeadDetail(LeadModel lead) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: lead)),
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
    const Color brandYellow = Color(0xFFFACC14);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Leads",
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
                _fetchLeads(isRefresh: true);
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
                          _fetchLeads(isRefresh: true);
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchLeads(isRefresh: true),
              color: Colors.black,
              backgroundColor: brandYellow,
              child: _isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: brandYellow),
                    )
                  : _errorMessage != null
                  ? _buildErrorState()
                  : _allLeads.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          _allLeads.length +
                          1 +
                          (_isLoadingMore || _hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _allLeads.length) {
                          return LeadCard(
                            lead: _allLeads[index],
                            onTap: () => _openLeadDetail(_allLeads[index]),
                          );
                        }

                        if (index == _allLeads.length) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${_allLeads.length} leads loaded",
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
            onPressed: () => _fetchLeads(isRefresh: true),
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
                ? "No leads found."
                : "No leads match \"$_searchQuery\".",
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
