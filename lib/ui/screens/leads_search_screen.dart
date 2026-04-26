import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../../data/models/mock_data.dart';
import '../widgets/car_card.dart';

class LeadsSearchScreen extends StatefulWidget {
  const LeadsSearchScreen({super.key});

  @override
  State<LeadsSearchScreen> createState() => _LeadsSearchScreenState();
}

class _LeadsSearchScreenState extends State<LeadsSearchScreen> {
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;
  CarStatus? _statusFilter;

  // High-efficiency filter logic
  List<CarModel> get _filteredLeads {
    return dashboardLeads.where((car) {
      // 1. Multi-field Text Search (Smart Search)
      final query = _searchQuery.toLowerCase();
      final matchesText =
          car.reg.toLowerCase().contains(query) ||
          car.make.toLowerCase().contains(query) ||
          car.model.toLowerCase().contains(query) ||
          (car.customerName?.toLowerCase().contains(query) ?? false) ||
          (car.phoneNumber?.contains(query) ?? false);

      // 2. Status Filter
      final matchesStatus =
          _statusFilter == null || car.status == _statusFilter;

      // 3. Date Range (Mock logic: assuming a 'createdAt' field exists)
      // For now, we skip date logic until your API provides timestamps.

      return matchesText && matchesStatus;
    }).toList();
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
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Name, Reg, Phone...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
      body: _filteredLeads.isEmpty
          ? const Center(child: Text("No matching leads found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLeads.length,
              itemBuilder: (context, index) =>
                  LeadCard(car: _filteredLeads[index]),
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

              // Status Chips
              const Text(
                "Status",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children:
                    [
                      CarStatus.lead,
                      CarStatus.negotiation,
                      CarStatus.offerAccepted,
                    ].map((s) {
                      return ChoiceChip(
                        label: Text(s.name),
                        selected: _statusFilter == s,
                        onSelected: (selected) {
                          setModalState(
                            () => _statusFilter = selected ? s : null,
                          );
                          setState(() {}); // Update main UI
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20),

              // Date Range Picker
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
                  }
                },
              ),
              const SizedBox(height: 20),

              // Clear All Button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _selectedDateRange = null;
                    });
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
