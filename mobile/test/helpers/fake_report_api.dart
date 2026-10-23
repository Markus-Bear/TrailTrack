import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/services/report_api.dart';

/// Records submitted reports, failing with each of [errors] in turn first.
class FakeReportApi extends ReportApi {
  FakeReportApi({List<ReportApiException>? errors}) : errors = errors ?? [];

  final List<ReportApiException> errors;
  final sent = <Map<String, Object?>>[];

  @override
  Future<ConditionReport> submit({
    required int trailId,
    required String token,
    required ConditionType conditionType,
    required Severity? severity,
    required String? note,
    required String clientRef,
  }) async {
    sent.add({
      'trailId': trailId,
      'token': token,
      'conditionType': conditionType,
      'severity': severity,
      'note': note,
      'clientRef': clientRef,
    });
    if (errors.isNotEmpty) throw errors.removeAt(0);
    return ConditionReport(
      id: 50,
      conditionType: conditionType,
      severity: severity,
      note: note,
      reportedAt: DateTime.now(),
    );
  }
}
