import 'condition_report.dart';
import 'trail.dart';

/// One trail in the search results.
class TrailSearchResult {
  const TrailSearchResult({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.lengthKm,
    required this.distanceKm,
    required this.latestReport,
  });

  final int id;
  final String name;
  final Difficulty difficulty;
  final double? lengthKm;

  /// Kilometres from the searcher to the nearest point of the trail, or
  /// null when searching by name only.
  final double? distanceKm;

  /// The trail's newest report from the last 7 days, or null.
  final ConditionReport? latestReport;

  /// e.g. "Moderate | 3.2 km | 1.2 km away".
  String get summary => [
    difficulty.label,
    if (lengthKm != null) '${lengthKm!.toStringAsFixed(1)} km',
    if (distanceKm != null) '${distanceKm!.toStringAsFixed(1)} km away',
  ].join(' | ');

  /// Parses one result from `GET /api/trails/search`.
  ///
  /// @param json the result
  /// @return the result
  factory TrailSearchResult.fromJson(Map<String, dynamic> json) {
    final latest = json['latestReport'] as Map<String, dynamic>?;
    return TrailSearchResult(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String).trim(),
      difficulty: Difficulty.parse(json['difficulty'] as String?),
      lengthKm: (json['lengthKm'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      latestReport: latest == null ? null : ConditionReport.fromJson(latest),
    );
  }
}
