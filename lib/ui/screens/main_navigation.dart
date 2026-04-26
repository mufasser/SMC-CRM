import 'package:flutter/material.dart';
import 'package:smc_crm/ui/screens/accepted_offers_screen.dart';
import 'package:smc_crm/ui/screens/dashboard_screen.dart';
import 'package:smc_crm/ui/screens/leads_search_screen.dart';
import 'package:smc_crm/ui/screens/stock_search_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const LeadsSearchScreen(), // Screen with heavy filters
    const StockSearchScreen(), // Screen with heavy filters
    const AcceptedOffersScreen(),
  ];

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Optimized: Using IndexedStack to preserve scroll positions and search states
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard), // Solid icon for active state
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Leads',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            activeIcon: Icon(Icons.handshake),
            label: 'Offers',
          ),
        ],
      ),
    );
  }
}
