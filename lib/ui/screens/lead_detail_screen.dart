import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this is in pubspec.yaml
import '../../data/models/car_model.dart';

class LeadDetailScreen extends StatelessWidget {
  final CarModel car; // Assigned as a final field
  final PageController _pageController = PageController();
  LeadDetailScreen({super.key, required this.car});

  // HELPER METHODS FOR BUTTONS
  Future<void> _launchWhatsApp(String phone) async {
    final Uri url = Uri.parse(
      "https://wa.me/$phone?text=Regarding the ${car.make} ${car.model} (${car.reg})",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch WhatsApp");
    }
  }

  Future<void> _launchCaller(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (!await launchUrl(url)) {
      debugPrint("Could not launch Dialer");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 250.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  children: [
                    // 1. THE SLIDER
                    PageView.builder(
                      controller: _pageController,
                      itemCount: car.images.length,
                      itemBuilder: (context, index) {
                        return Hero(
                          tag:
                              'car-img-${car.id}', // Keep the Hero for the first image
                          child: Image.network(
                            car.images[index].url,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 50),
                            ),
                          ),
                        );
                      },
                    ),
                    // 2. THE IMAGE COUNTER OVERLAY
                    Positioned(
                      bottom: 60, // Adjust based on your TabBar height
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListenableBuilder(
                          listenable: _pageController,
                          builder: (context, child) {
                            int currentPage = _pageController.hasClients
                                ? _pageController.page?.round() ?? 0
                                : 0;
                            return Text(
                              "${currentPage + 1} / ${car.images.length}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${car.year} ${car.make} ${car.model}",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Reg: ${car.reg} | Mileage: ${car.mileage} miles",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: [
                    Tab(text: "Car Summary"),
                    Tab(text: "Customer"),
                    Tab(text: "Documents"),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _CarSummaryTab(car: car), // Passed car data
              _CustomerInfoTab(car: car), // Passed car data
              const Center(child: Text("Documents Placeholder")),
            ],
          ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  // Now correctly using the car object from the constructor
                  onPressed: () =>
                      _launchWhatsApp(car.phoneNumber ?? "07123456789"),
                  icon: const Icon(Icons.message, color: Colors.white),
                  label: const Text("WhatsApp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () =>
                      _launchCaller(car.phoneNumber ?? "07123456789"),
                  icon: const Icon(Icons.phone, color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _CarSummaryTab extends StatelessWidget {
  final CarModel car;
  const _CarSummaryTab({required this.car});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ProfitCalculatorSection(
          costPrice: car.price - 2000,
        ), // Dynamic profit math
        const SizedBox(height: 25),
        const Text(
          "Vehicle Specifications",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        _specRow("Color", car.color ?? "Standard"),
        _specRow("Price", "£${car.price}"),
        _specRow("Registration", car.reg),
        const Divider(height: 40),
        const Text(
          "Condition Report",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Excellent condition, full service history. Ready for retail.",
          style: TextStyle(color: Colors.grey, height: 1.5),
        ),
      ],
    );
  }

  Widget _specRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _CustomerInfoTab extends StatelessWidget {
  final CarModel car;
  const _CustomerInfoTab({required this.car});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          "Customer Profile",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Card(
          elevation: 0,
          color: const Color(0xFFF8F9FA),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(car.customerName ?? "New Lead"),
            subtitle: Text("Status: ${car.status}"),
          ),
        ),
        const SizedBox(height: 20),
        _contactTile(
          Icons.phone_outlined,
          "Phone",
          car.phoneNumber ?? "+44 0000 000000",
          Colors.green,
        ),
        _contactTile(
          Icons.email_outlined,
          "Email",
          "customer@smc-crm.com",
          Colors.blue,
        ),
      ],
    );
  }

  Widget _contactTile(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ProfitCalculatorSection extends StatefulWidget {
  final double costPrice;
  const _ProfitCalculatorSection({required this.costPrice});
  @override
  State<_ProfitCalculatorSection> createState() =>
      _ProfitCalculatorSectionState();
}

class _ProfitCalculatorSectionState extends State<_ProfitCalculatorSection> {
  double salePrice = 0;
  double profit = 0;

  @override
  void initState() {
    super.initState();
    salePrice = widget.costPrice + 1500;
    _calculate();
  }

  void _calculate() {
    setState(() {
      profit = salePrice - widget.costPrice;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profit Calculator",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Sale Price (£)",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    salePrice = double.tryParse(val) ?? 0;
                    _calculate();
                  },
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    "Estimated Profit",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "£${profit.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: profit > 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _buildImageGallery(List<CarImage> images) {
  return Stack(
    children: [
      SizedBox(
        height: 250,
        child: PageView.builder(
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Hero(
              tag: 'car-img-${images[index].id}',
              child: Image.network(images[index].url, fit: BoxFit.cover),
            );
          },
        ),
      ),
      // Image Counter Badge (e.g., 1/12)
      Positioned(
        bottom: 10,
        right: 10,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "${images.length} Photos",
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    ],
  );
}
