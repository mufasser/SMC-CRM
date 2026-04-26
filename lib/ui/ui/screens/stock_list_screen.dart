import 'package:flutter/material.dart';

class StockListScreen extends StatelessWidget {
  const StockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock Inventory")),
      body: const Center(child: Text("Stock list will appear here.")),
    );
  }
}
