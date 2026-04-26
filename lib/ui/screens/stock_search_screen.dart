import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../../data/models/mock_data.dart';
import '../widgets/stock_card.dart'; // InventoryCard

class StockSearchScreen extends StatefulWidget {
  const StockSearchScreen({super.key});

  @override
  State<StockSearchScreen> createState() => _StockSearchScreenState();
}

class _StockSearchScreenState extends State<StockSearchScreen> {
  String _searchQuery = "";
  RangeValues _priceRange = const RangeValues(0, 100000);
  CarStatus? _statusFilter;

  List<CarModel> get _filteredStock {
    return dashboardLeads.where((car) {
      // Only show items that are InStock or Sold for this screen
      final isInventory =
          car.status == CarStatus.inStock || car.status == CarStatus.sold;

      final query = _searchQuery.toLowerCase();
      final matchesText =
          car.reg.toLowerCase().contains(query) ||
          car.make.toLowerCase().contains(query) ||
          car.model.toLowerCase().contains(query);

      final matchesPrice =
          car.price >= _priceRange.start && car.price <= _priceRange.end;
      final matchesStatus =
          _statusFilter == null || car.status == _statusFilter;

      return isInventory && matchesText && matchesPrice && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Stock Inventory",
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
                      hintText: "Search Make, Model, Reg...",
                      prefixIcon: const Icon(Icons.search),
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
      body: _filteredStock.isEmpty
          ? const Center(child: Text("No vehicles found in stock"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredStock.length,
              itemBuilder: (context, index) =>
                  InventoryCard(car: _filteredStock[index]),
            ),
    );
  }

  Widget _buildFilterButton() {
    bool hasActiveFilters =
        _statusFilter != null ||
        _priceRange.start > 0 ||
        _priceRange.end < 100000;
    return IconButton(
      onPressed: _showFilterSheet,
      icon: Icon(
        Icons.filter_list,
        color: hasActiveFilters ? Colors.blue : Colors.black,
      ),
      style: IconButton.styleFrom(
        backgroundColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
                "Inventory Filters",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 25),
              const Text(
                "Status",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text("Available"),
                    selected: _statusFilter == CarStatus.inStock,
                    onSelected: (val) {
                      setModalState(
                        () => _statusFilter = val ? CarStatus.inStock : null,
                      );
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text("Sold"),
                    selected: _statusFilter == CarStatus.sold,
                    onSelected: (val) {
                      setModalState(
                        () => _statusFilter = val ? CarStatus.sold : null,
                      );
                      setState(() {});
                    },
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                "Price Range: £${_priceRange.start.round()} - £${_priceRange.end.round()}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 100000,
                divisions: 20,
                labels: RangeLabels(
                  "£${_priceRange.start.round()}",
                  "£${_priceRange.end.round()}",
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
