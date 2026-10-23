import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_detail.dart';
import 'package:trailtrack/services/trail_api.dart';

/// The Glenbarrow Waterfall Loop with one mud report from two hours ago.
TrailDetail testTrailDetail({List<ConditionReport>? reports}) {
  final recent =
      reports ??
      [
        ConditionReport(
          id: 3,
          conditionType: ConditionType.mud,
          severity: Severity.moderate,
          note: 'Muddy by the waterfall steps',
          reportedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ];
  return TrailDetail(
    id: 9,
    name: 'Glenbarrow - Waterfall Loop',
    difficulty: Difficulty.moderate,
    lengthKm: 3.2,
    timeToComplete: '1 hour',
    description: 'A loop past the Glenbarrow waterfall.',
    website: null,
    currentConditions: recent,
    recentReports: recent,
  );
}

/// Answers detail requests with [detail], or throws [error].
class FakeDetailTrailApi extends TrailApi {
  FakeDetailTrailApi({this.detail, this.error});

  TrailDetail? detail;
  TrailApiException? error;
  int calls = 0;

  @override
  Future<TrailDetail> fetchTrailDetail(int id) async {
    calls++;
    if (error != null) throw error!;
    return detail ?? testTrailDetail();
  }
}
