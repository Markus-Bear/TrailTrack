/// What a hiker found on the trail, matching the backend's ConditionType.
enum ConditionType {
  clear('CLEAR', 'Clear'),
  mud('MUD', 'Mud'),
  flooding('FLOODING', 'Flooding'),
  fallenTree('FALLEN_TREE', 'Fallen tree'),
  stormDamage('STORM_DAMAGE', 'Storm damage'),
  closure('CLOSURE', 'Closure'),
  forestryWork('FORESTRY_WORK', 'Forestry work'),
  livestock('LIVESTOCK', 'Livestock'),
  other('OTHER', 'Other');

  const ConditionType(this.apiName, this.label);

  /// The name the backend uses, e.g. FALLEN_TREE.
  final String apiName;
  final String label;

  /// @param value the backend's name, e.g. "MUD"
  /// @return the matching type, or [ConditionType.other] if unrecognised
  static ConditionType parse(String? value) => ConditionType.values.firstWhere(
    (t) => t.apiName == value,
    orElse: () => ConditionType.other,
  );
}

/// How badly a condition affects the trail.
enum Severity {
  low('LOW', 'Low'),
  moderate('MODERATE', 'Moderate'),
  high('HIGH', 'High');

  const Severity(this.apiName, this.label);

  final String apiName;
  final String label;

  /// @param value the backend's name, e.g. "HIGH"
  /// @return the matching severity, or null for none or an unknown value
  static Severity? parse(String? value) {
    for (final s in Severity.values) {
      if (s.apiName == value) return s;
    }
    return null;
  }
}

/// A condition report as shown to other hikers. It never says who sent it.
class ConditionReport {
  const ConditionReport({
    required this.id,
    required this.conditionType,
    required this.severity,
    required this.note,
    required this.reportedAt,
  });

  final int id;
  final ConditionType conditionType;

  /// Null for clear reports.
  final Severity? severity;
  final String? note;
  final DateTime reportedAt;

  /// e.g. "Fallen tree, high", or "Clear".
  String get summary => severity == null
      ? conditionType.label
      : '${conditionType.label}, ${severity!.label.toLowerCase()}';

  /// Parses one of the backend's report objects.
  ///
  /// @param json the report
  /// @return the report
  factory ConditionReport.fromJson(Map<String, dynamic> json) =>
      ConditionReport(
        id: (json['id'] as num).toInt(),
        conditionType: ConditionType.parse(json['conditionType'] as String?),
        severity: Severity.parse(json['severity'] as String?),
        note: json['note'] as String?,
        reportedAt: DateTime.parse(json['reportedAt'] as String),
      );
}

/// How long ago something happened, e.g. "just now", "3 hours ago",
/// "yesterday" or "4 days ago".
///
/// @param time when it happened
/// @param now the current time
String timeAgo(DateTime time, DateTime now) {
  final age = now.difference(time);
  if (age.inMinutes < 1) return 'just now';
  if (age.inHours < 1) {
    return age.inMinutes == 1 ? '1 minute ago' : '${age.inMinutes} minutes ago';
  }
  if (age.inDays < 1) {
    return age.inHours == 1 ? '1 hour ago' : '${age.inHours} hours ago';
  }
  if (age.inDays == 1) return 'yesterday';
  return '${age.inDays} days ago';
}
