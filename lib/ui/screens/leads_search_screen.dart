import 'package:flutter/material.dart';
import '../../data/models/lead_model.dart'; // Import the real model
import '../../data/services/crm_service.dart'; // Import the service
import '../widgets/car_card.dart';

class LeadsSearchScreen extends StatefulWidget {
  const LeadsSearchScreen({super.key});

  @override
  State<LeadsSearchScreen> createState() => _LeadsSearchScreenState();
}

class _LeadsSearchScreenState extends State<LeadsSearchScreen> {
  final CRMService _crmService = CRMService();
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  String? _statusFilter; // Using String to match your API status values

  List<LeadModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _performSearch(); // Initial load
  }

  /// Fetches filtered data from the real API
  Future<void> _performSearch() async {
    setState(() => _isLoading = true);

    try {
      // Pass the query and status to your API service
      final result = await _crmService.fetchData(
        endpoint: '/leads',
        search: _searchQuery,
        // If your API supports status filtering, pass it here
      );

      setState(() {
        _searchResults = result['items'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Search error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Search Leads",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (val) {
                      setState(() => _searchQuery = val);
                      _performSearch();
                    },
                    decoration: InputDecoration(
                      hintText: "Name, Reg, Phone...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildFilterButton(),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFACC14)),
            )
          : _searchResults.isEmpty
          ? const Center(child: Text("No matching leads found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final item = _searchResults[index];
                // FIXED: Changed 'car' to 'lead' to match your updated LeadCard
                return LeadCard(lead: item);
              },
            ),
    );
  }

  Widget _buildFilterButton() {
    bool hasActiveFilters = _statusFilter != null || _selectedDateRange != null;
    return Stack(
      children: [
        IconButton(
          onPressed: _showFilterSheet,
          icon: Icon(
            Icons.tune,
            color: hasActiveFilters ? Colors.blue : Colors.black,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (hasActiveFilters)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              height: 10,
              width: 10,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filter Leads",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                "Status",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: ["NEW_LEAD", "NEGOTIATION", "OFFER_ACCEPTED"].map((
                  status,
                ) {
                  return ChoiceChip(
                    label: Text(status.replaceAll("_", " ")),
                    selected: _statusFilter == status,
                    onSelected: (selected) {
                      setModalState(
                        () => _statusFilter = selected ? status : null,
                      );
                      setState(() {});
                      _performSearch(); // Re-fetch on filter change
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range),
                title: Text(
                  _selectedDateRange == null
                      ? "Select Date Range"
                      : "${_selectedDateRange!.start.toString().split(' ')[0]} to ${_selectedDateRange!.end.toString().split(' ')[0]}",
                ),
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (range != null) {
                    setModalState(() => _selectedDateRange = range);
                    setState(() {});
                    _performSearch();
                  }
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _selectedDateRange = null;
                    });
                    _performSearch();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Clear All Filters",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
