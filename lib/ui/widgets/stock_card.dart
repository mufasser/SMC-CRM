import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../screens/lead_detail_screen.dart';
import 'uk_reg_plate.dart';

class InventoryCard extends StatelessWidget {
  final CarModel car;

  const InventoryCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    // Brand Colors from Theme
    final Color brandYellow = Theme.of(context).primaryColor;
    final double estimatedPurchasePrice = car.price * 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LeadDetailScreen(car: car)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image kept as requested for Stock, but styled cleaner
                  Hero(
                    tag: 'car-img-${car.id}',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        car.displayImageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // MAIN INFO
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${car.make} ${car.model}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${car.year} • ${car.mileage} miles",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Now using your official UK Plate Widget
                        UkRegPlate(reg: car.reg, fontSize: 10),
                      ],
                    ),
                  ),

                  // PRICE
                  Text(
                    "£${car.price.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // PROFIT BAR (Cleaned up with Brand logic)
              _buildProfitMargin(estimatedPurchasePrice, car.price),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfitMargin(double purchase, double sale) {
    final profit = sale - purchase;
    final marginPercent = (profit / purchase) * 100;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Neutral clean background
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "Potential Profit: £${profit.toStringAsFixed(0)}",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${marginPercent.toStringAsFixed(1)}%",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
