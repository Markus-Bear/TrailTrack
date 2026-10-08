import 'package:flutter/material.dart';

import '../models/trail.dart';
import 'difficulty_style.dart';

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

/// Key to the line colour and pattern for each difficulty.
class DifficultyLegend extends StatelessWidget {
  const DifficultyLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Card(
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in [
                Difficulty.easy,
                Difficulty.moderate,
                Difficulty.challenging,
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomPaint(
                        size: const Size(28, 8),
                        painter: _LineSample(d),
                      ),
                      const SizedBox(width: 8),
                      Text(d.label, style: text.labelMedium),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short horizontal line drawn in a difficulty's colour and pattern.
class _LineSample extends CustomPainter {
  const _LineSample(this.difficulty);

  final Difficulty difficulty;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 4.0;
    final y = size.height / 2;
    final paint = Paint()
      ..color = difficultyColour(difficulty)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    final pattern = difficultyPattern(difficulty);
    final segments = pattern.segments;
    final spacing = pattern.spacingFactor;
    if (segments != null) {
      // Dashes are drawn at half length so at least one gap fits.
      var x = 0.0;
      while (x < size.width) {
        final end = (x + segments[0] / 2).clamp(0.0, size.width);
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x += (segments[0] + segments[1]) / 2;
      }
    } else if (spacing != null) {
      for (var x = width / 2; x < size.width; x += width * spacing) {
        canvas.drawCircle(Offset(x, y), width / 2, paint);
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_LineSample old) => old.difficulty != difficulty;
}
