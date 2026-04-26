import 'package:flutter/material.dart';

class UkRegPlate extends StatelessWidget {
  final String reg;
  final bool isFrontPlate; // true for white, false for yellow
  final double fontSize;

  const UkRegPlate({
    super.key,
    required this.reg,
    this.isFrontPlate = false, // Default to yellow (rear plate style)
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    // UK Plate Yellow: #FACC14 (Matches your Brand Yellow perfectly)
    // UK Plate Blue: #003399
    const Color ukBlue = Color(0xFF003399);

    return IntrinsicWidth(
      child: Container(
        height: fontSize + 12,
        decoration: BoxDecoration(
          color: isFrontPlate ? Colors.white : const Color(0xFFFACC14),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black.withOpacity(0.2), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. The UK/EU Style Blue Strip
            Container(
              width: (fontSize / 2) + 12,
              decoration: const BoxDecoration(
                color: ukBlue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                ),
              ),
              child: Center(
                child: Text(
                  "UK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize * 0.9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // 2. The Registration Number
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                reg.toUpperCase().replaceAll(' ', ''), // Clean formatting
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace', // Simulates the Charles Wright font
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
