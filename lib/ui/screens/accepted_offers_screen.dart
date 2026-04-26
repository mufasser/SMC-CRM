import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../../data/models/mock_data.dart';
import '../widgets/car_card.dart';

class AcceptedOffersScreen extends StatefulWidget {
  const AcceptedOffersScreen({super.key});

  @override
  State<AcceptedOffersScreen> createState() => _AcceptedOffersScreenState();
}

class _AcceptedOffersScreenState extends State<AcceptedOffersScreen> {
  String _searchQuery = "";
  final Color brandYellow = const Color(0xFFFACC14);

  // Efficiency Filter: Specifically for Offer Accepted status
  List<CarModel> get _acceptedLeads {
    return dashboardLeads.where((car) {
      // 1. First check the status
      final isAccepted = car.status == CarStatus.offerAccepted;

      // 2. Process search query
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return isAccepted;

      // 3. Multi-field search with Null Safety
      // We use '?? false' so if a field is null, it doesn't crash the condition
      final matchesName =
          car.customerName?.toLowerCase().contains(query) ?? false;
      final matchesReg = car.reg.toLowerCase().contains(query);
      final matchesPhone = car.phoneNumber?.contains(query) ?? false;

      return isAccepted && (matchesName || matchesReg || matchesPhone);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Accepted Offers",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: brandYellow,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Search Customer or Reg...",
                prefixIcon: const Icon(
                  Icons.handshake_outlined,
                  color: Colors.black,
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: brandYellow, width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _acceptedLeads.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _acceptedLeads.length,
              itemBuilder: (context, index) =>
                  LeadCard(car: _acceptedLeads[index]),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[200]),
          const SizedBox(height: 16),
          const Text(
            "No accepted offers yet",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
