import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_detail.dart';

void main() {
  group('ConditionReport', () {
    test('parses a report from the API', () {
      final report = ConditionReport.fromJson({
        'id': 3,
        'trailId': 9,
        'conditionType': 'FALLEN_TREE',
        'severity': 'HIGH',
        'note': 'Blocks the path',
        'status': 'OPEN',
        'reportedAt': '2026-10-23T07:40:32Z',
      });

      expect(report.conditionType, ConditionType.fallenTree);
      expect(report.severity, Severity.high);
      expect(report.summary, 'Fallen tree, high');
      expect(report.reportedAt, DateTime.utc(2026, 10, 23, 7, 40, 32));
    });

    test('a clear report has no severity', () {
      final report = ConditionReport.fromJson({
        'id': 4,
        'conditionType': 'CLEAR',
        'severity': null,
        'reportedAt': '2026-10-23T07:40:32Z',
      });

      expect(report.severity, isNull);
      expect(report.summary, 'Clear');
    });
  });

  test('timeAgo says how long ago a report was made', () {
    final now = DateTime(2026, 10, 23, 12);

    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now), 'just now');
    expect(
      timeAgo(now.subtract(const Duration(minutes: 5)), now),
      '5 minutes ago',
    );
    expect(timeAgo(now.subtract(const Duration(hours: 1)), now), '1 hour ago');
    expect(timeAgo(now.subtract(const Duration(hours: 30)), now), 'yesterday');
    expect(timeAgo(now.subtract(const Duration(days: 4)), now), '4 days ago');
  });

  test(
    'TrailDetail parses the detail response, treating blank text as missing',
    () {
      final detail = TrailDetail.fromJson({
        'id': 9,
        'name': 'Glenbarrow - Waterfall Loop ',
        'difficulty': 'Moderate',
        'lengthKm': 3.2,
        'timeToComplete': '1 hour',
        'description': 'A loop past the waterfall.',
        'website': '  ',
        'waymarkColour': 'blue',
        'currentConditions': [],
        'recentReports': [
          {
            'id': 3,
            'conditionType': 'MUD',
            'severity': 'MODERATE',
            'reportedAt': '2026-10-23T07:40:32Z',
          },
        ],
      });

      expect(detail.name, 'Glenbarrow - Waterfall Loop');
      expect(detail.difficulty, Difficulty.moderate);
      expect(detail.website, isNull);
      expect(detail.recentReports.single.conditionType, ConditionType.mud);
    },
  );
}
