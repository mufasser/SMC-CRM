import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../../data/models/mock_data.dart';
import '../widgets/car_card.dart'; // Ensure this contains LeadCard

class LeadsListScreen extends StatelessWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Deal Pipeline",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "New Leads"),
              Tab(text: "Negotiation"),
              Tab(text: "Offer Accepted"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildLeadList(CarStatus.lead),
            _buildLeadList(CarStatus.negotiation),
            _buildLeadList(CarStatus.offerAccepted),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadList(CarStatus status) {
    // Filter the global list based on the tab status
    final list = dashboardLeads.where((car) => car.status == status).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_late_outlined,
              size: 50,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text(
              "No deals in ${status.name}",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) => LeadCard(
        car: list[index],
        onStatusChanged: () {
          // For now, this just triggers a UI rebuild
          // When we have APIs, this will re-fetch data
          (context as Element).markNeedsBuild();
        },
      ),
    );
  }
}
