import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/services/report_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';
import 'package:trailtrack/view_models/report_view_model.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_report_api.dart';

Future<AuthViewModel> _loggedIn([InMemorySessionStore? store]) async {
  final auth = AuthViewModel(
    api: FakeAuthApi(),
    store: store ?? InMemorySessionStore(testSession()),
  );
  await auth.restore();
  return auth;
}

void main() {
  test('nothing can be sent until a condition is chosen', () async {
    final model = ReportViewModel(
      api: FakeReportApi(),
      auth: await _loggedIn(),
      trailId: 9,
    );

    expect(model.canSubmit, isFalse);
    model.selectCondition(ConditionType.mud);
    expect(model.canSubmit, isTrue);
    expect(model.severity, Severity.moderate);
  });

  test(
    'sends the chosen condition, severity and note with the token',
    () async {
      final api = FakeReportApi();
      final model = ReportViewModel(
        api: api,
        auth: await _loggedIn(),
        trailId: 9,
      );
      model
        ..selectCondition(ConditionType.fallenTree)
        ..selectSeverity(Severity.high);

      final report = await model.submit(note: 'Across the path');

      expect(report, isNotNull);
      expect(api.sent.single['trailId'], 9);
      expect(api.sent.single['token'], 'signed-token');
      expect(api.sent.single['conditionType'], ConditionType.fallenTree);
      expect(api.sent.single['severity'], Severity.high);
    },
  );

  test(
    'a clear report has no severity and hides the severity choice',
    () async {
      final api = FakeReportApi();
      final model = ReportViewModel(
        api: api,
        auth: await _loggedIn(),
        trailId: 9,
      );

      model.selectCondition(ConditionType.clear);
      expect(model.needsSeverity, isFalse);
      await model.submit();

      expect(api.sent.single['severity'], isNull);
    },
  );

  test(
    'a retry after a dropped connection reuses the same clientRef',
    () async {
      final api = FakeReportApi(
        errors: [const ReportApiException('No connection, try again.')],
      );
      final model = ReportViewModel(
        api: api,
        auth: await _loggedIn(),
        trailId: 9,
      )..selectCondition(ConditionType.mud);

      expect(await model.submit(), isNull);
      expect(model.error, 'No connection, try again.');
      expect(await model.submit(), isNotNull);

      expect(api.sent, hasLength(2));
      expect(api.sent[0]['clientRef'], api.sent[1]['clientRef']);
    },
  );

  test('an expired login logs the user out and asks them to log in', () async {
    final store = InMemorySessionStore(testSession());
    final auth = await _loggedIn(store);
    final model = ReportViewModel(
      api: FakeReportApi(
        errors: [const ReportApiException('expired', sessionExpired: true)],
      ),
      auth: auth,
      trailId: 9,
    )..selectCondition(ConditionType.mud);

    await model.submit();

    expect(model.sessionExpired, isTrue);
    expect(auth.isLoggedIn, isFalse);
    expect(store.saved, isNull);
  });
}
