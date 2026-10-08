import 'package:flutter/material.dart';

import '../models/trail.dart';

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

/// Error message with a Retry button.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(message)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Preview of the selected trail: name, difficulty and length.
class TrailCard extends StatelessWidget {
  const TrailCard({super.key, required this.trail});

  final Trail trail;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final summary = [
      trail.difficulty.label,
      if (trail.lengthKm != null) '${trail.lengthKm!.toStringAsFixed(1)} km',
    ].join(' | ');
    // The bottom margin keeps the attribution bar visible below the card.
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trail.name, style: text.titleMedium),
              const SizedBox(height: 4),
              Text(summary, style: text.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
