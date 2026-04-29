import 'package:flutter/material.dart';
import '../../data/models/lead_model.dart';
import '../../data/models/offer_model.dart';
import '../../data/models/stock_model.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/crm_service.dart';
import 'lead_detail_screen.dart';
import 'offer_detail_screen.dart';
import 'stock_detail_screen.dart';
import '../widgets/stock_card.dart'; // Ensure these widgets accept LeadModel
import '../widgets/car_card.dart'; // Ensure these widgets accept LeadModel
import '../widgets/offer_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final CRMService _crmService = CRMService();
  final AuthService _authService = AuthService();

  // Data lists
  List<LeadModel> _leads = [];
  List<OfferModel> _offers = [];
  List<StockModel> _stock = [];

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _summary = {};
  String _userName = '';
  String _tenantName = '';
  String? _generatedAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // PLACE CODE: Fetching the 3 APIs in parallel
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait<dynamic>([
        _crmService.fetchDashboardStats(),
        _authService.getDashboardStats(),
        _authService.getUserName(),
        _authService.getTenantName(),
        _crmService.fetchData(endpoint: '/leads', limit: 10),
        _crmService.fetchOffers(limit: 10),
        _crmService.fetchStock(limit: 10),
      ]);

      final liveStatsResponse = results[0] as Map<String, dynamic>;
      final cachedStats = results[1] as Map<String, dynamic>;
      final liveStats =
          (liveStatsResponse['stats'] as Map<String, dynamic>?) ?? const {};
      final resolvedStats = liveStats.isNotEmpty ? liveStats : cachedStats;
      final resolvedSummary =
          (liveStatsResponse['summary'] as Map<String, dynamic>?) ?? const {};
      final generatedAt = liveStatsResponse['generatedAt']?.toString();

      if (liveStats.isNotEmpty) {
        await _authService.saveDashboardStats(liveStats);
      }

      setState(() {
        _stats = resolvedStats;
        _summary = resolvedSummary;
        _generatedAt = generatedAt;
        _userName = (results[2] as String?) ?? '';
        _tenantName = (results[3] as String?) ?? '';
        _leads = results[4]['items'];
        _offers = results[5]['items'];
        _stock = results[6]['items'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error (e.g., show SnackBar)
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFFACC14);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "Sell My Car Today",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _loadAllData, // Refresh button
              icon: const Icon(Icons.refresh, color: Colors.black),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: brandYellow))
            : Column(
                children: [
                  // _buildOverviewHeader(brandYellow),
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Live Snapshot",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_generatedAt != null) ...[
                          Text(
                            "Updated ${_formatGeneratedAt(_generatedAt!)}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat(
                              "Dealer Leads",
                              _statValue('totalLoginDealerLeads'),
                              brandYellow,
                            ),
                            _buildMiniStat(
                              "Today Leads",
                              _statValue('totalTodayLeads'),
                              brandYellow,
                            ),
                            _buildMiniStat(
                              "Accepted",
                              _statValue('totalAcceptedOffers'),
                              Colors.green,
                            ),
                            _buildMiniStat(
                              "In Stock",
                              _statValue('totalAvailableInStockVehicles'),
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryStrip(
                            "Today's Offers",
                            _statValue('totalTodayAcceptedOffers'),
                            Icons.handshake_outlined,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryStrip(
                            "Visible Stock",
                            _summaryValue('stock', 'visibleInApiVehicles'),
                            Icons.public_outlined,
                            Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const TabBar(
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: brandYellow,
                    tabs: [
                      Tab(text: "Leads"),
                      Tab(text: "Offers"),
                      Tab(text: "Stock"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildList(_leads, isStock: false),
                        _buildOffersList(_offers),
                        _buildStockList(_stock),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewHeader(Color brandYellow) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: brandYellow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tenantName.isEmpty ? "Sell My Car Today" : _tenantName,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _userName.isEmpty ? "Dashboard" : "Welcome, $_userName",
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Server login stats are shown here. Tabs below still show recent live records.",
            style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color == Colors.black ? Colors.black : color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStrip(
    String label,
    String value,
    IconData icon,
    Color accent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statValue(String key) {
    final value = _stats[key];
    if (value == null) {
      return '0';
    }
    return value.toString();
  }

  String _summaryValue(String section, String key) {
    final sectionMap = _summary[section];
    if (sectionMap is! Map<String, dynamic>) {
      return '0';
    }
    final value = sectionMap[key];
    return value?.toString() ?? '0';
  }

  String _formatGeneratedAt(String isoString) {
    final parsed = DateTime.tryParse(isoString)?.toLocal();
    if (parsed == null) {
      return isoString;
    }

    final hour = parsed.hour == 0
        ? 12
        : parsed.hour > 12
        ? parsed.hour - 12
        : parsed.hour;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return "${parsed.day}/${parsed.month}/${parsed.year} $hour:$minute $suffix";
  }

  // Updated List Builder using LeadModel
  Widget _buildList(List<LeadModel> list, {required bool isStock}) {
    if (list.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return LeadCard(
            lead: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LeadDetailScreen(lead: item)),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOffersList(List<OfferModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return OfferCard(
            offer: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OfferDetailScreen(offer: item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStockList(List<StockModel> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return InventoryCard(
            stock: item,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      StockDetailScreen(stockId: item.id, initialStock: item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
