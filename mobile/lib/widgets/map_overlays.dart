import 'package:flutter/material.dart';

/// Required credits for the map tiles (ODbL) and trail data (CC BY 4.0).
class AttributionBar extends StatelessWidget {
  const AttributionBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomRight,
        child: Container(
          color: Colors.white.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(
            '© OpenStreetMap contributors | Trail data: Sport Ireland (CC BY 4.0)',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}
