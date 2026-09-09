import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// Kachel für einen einzelnen Wert im Dashboard (z.B. Temperatur).
class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
  });

  /// Baut die Kachel: Titel oben, Wert groß darunter.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: boxStyle(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 18),

          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}