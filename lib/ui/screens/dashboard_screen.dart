import 'package:flutter/material.dart';
import '../../data/models/mock_data.dart';
import '../../data/models/car_model.dart';
import '../widgets/stock_card.dart'; // InventoryCard
import '../widgets/car_card.dart'; // LeadCard

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandYellow = Color(0xFFFACC14);
    const Color brandBlack = Color(0xFF000000);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            "SMC CRM",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none, color: Colors.black),
            ),
          ],
        ),
        body: Column(
          children: [
            // 1. HORIZONTAL METRIC BAR
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat(
                    "Total",
                    "${dashboardLeads.length}",
                    brandYellow,
                  ),
                  _buildMiniStat("Leads", "12", brandYellow),
                  _buildMiniStat("Sold", "8", Colors.green),
                  _buildMiniStat("Profit", "£4.2k", Colors.purple),
                ],
              ),
            ),

            // 2. TABS
            const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: brandYellow,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(text: "Leads"),
                Tab(text: "Acpt Offers"),
                Tab(text: "Stock"),
              ],
            ),

            // 3. TAB VIEWS
            Expanded(
              child: TabBarView(
                children: [
                  _buildList(CarStatus.lead),
                  _buildList(CarStatus.offerAccepted),
                  _buildList(CarStatus.inStock),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildList(CarStatus status) {
    final list = dashboardLeads.where((c) => c.status == status).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        // Use InventoryCard for Stock, LeadCard for others
        return status == CarStatus.inStock
            ? InventoryCard(car: list[index])
            : LeadCard(car: list[index]);
      },
    );
  }
}
