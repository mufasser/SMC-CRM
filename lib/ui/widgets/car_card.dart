import 'package:flutter/material.dart';
import '../../data/models/car_model.dart';
import '../screens/lead_detail_screen.dart';
import 'uk_reg_plate.dart';

class LeadCard extends StatelessWidget {
  final CarModel car;
  final VoidCallback? onStatusChanged; // Added to fix the compilation error

  const LeadCard({
    super.key,
    required this.car,
    this.onStatusChanged, // Added to constructor
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeadDetailScreen(car: car)),
          );
          // If something changed in the detail screen, refresh the list
          if (onStatusChanged != null) onStatusChanged!();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. MAIN DETAILS (Left side)
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
                    const SizedBox(height: 4),
                    Text(
                      "${car.mileage} miles • ${car.year} • ${car.color}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),

                    // USING THE UK PLATE WIDGET
                    UkRegPlate(reg: car.reg),
                  ],
                ),
              ),

              // 2. STATUS & NAVIGATION (Right side)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(context, car.status),
                  const SizedBox(height: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, CarStatus status) {
    return Text(
      status.name.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: _getStatusColor(status),
      ),
    );
  }

  Color _getStatusColor(CarStatus status) {
    switch (status) {
      case CarStatus.lead:
        return Colors.blue;
      case CarStatus.negotiation:
        return Colors.orange;
      case CarStatus.offerAccepted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
