import 'condition_report.dart';
import 'trail.dart';

/// Everything on a trail's detail page: the register's information plus the
/// trail's recent condition reports.
class TrailDetail {
  const TrailDetail({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.lengthKm,
    required this.timeToComplete,
    required this.description,
    required this.website,
    required this.currentConditions,
    required this.recentReports,
  });

  final int id;
  final String name;
  final Difficulty difficulty;
  final double? lengthKm;
  final String? timeToComplete;
  final String? description;
  final String? website;

  /// The newest report of each condition type, newest first.
  final List<ConditionReport> currentConditions;

  /// Reports from the last 7 days, newest first.
  final List<ConditionReport> recentReports;

  /// Parses the backend's `GET /api/trails/{id}` response.
  ///
  /// @param json the response body
  /// @return the trail detail
  factory TrailDetail.fromJson(Map<String, dynamic> json) {
    List<ConditionReport> reports(String field) => [
      for (final r in (json[field] as List? ?? const []))
        ConditionReport.fromJson(r as Map<String, dynamic>),
    ];
    String? text(String field) {
      final value = (json[field] as String?)?.trim();
      return value == null || value.isEmpty ? null : value;
    }

    return TrailDetail(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String).trim(),
      difficulty: Difficulty.parse(json['difficulty'] as String?),
      lengthKm: (json['lengthKm'] as num?)?.toDouble(),
      timeToComplete: text('timeToComplete'),
      description: text('description'),
      website: text('website'),
      currentConditions: reports('currentConditions'),
      recentReports: reports('recentReports'),
    );
  }
}
