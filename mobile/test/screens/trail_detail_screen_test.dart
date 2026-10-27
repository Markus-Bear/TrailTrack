import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/screens/trail_detail_screen.dart';
import 'package:trailtrack/services/report_api.dart';
import 'package:trailtrack/services/trail_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_report_api.dart';
import '../helpers/fake_trail_detail.dart';

Future<void> _open(
  WidgetTester tester,
  TrailApi api, {
  AuthViewModel? auth,
  ReportApi? reportApi,
}) async {
  await tester.pumpWidget(
    withAuth(
      MaterialApp(
        home: TrailDetailScreen(
          trailId: 9,
          trailName: 'Glenbarrow - Waterfall Loop',
          api: api,
          reportApi: reportApi,
        ),
      ),
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the trail facts and its recent reports', (tester) async {
    await _open(tester, FakeDetailTrailApi());

    expect(find.text('3.2 km'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
    expect(find.text('Mud, moderate | 2 hours ago'), findsOneWidget);
    expect(find.textContaining('Muddy by the waterfall steps'), findsOneWidget);
  });

  testWidgets('a trail without reports says so', (tester) async {
    await _open(
      tester,
      FakeDetailTrailApi(detail: testTrailDetail(reports: const [])),
    );

    expect(find.text('No recent reports'), findsOneWidget);
    expect(find.text('Recent reports'), findsNothing);
  });

  testWidgets('a trail that no longer exists says so, with no Retry', (
    tester,
  ) async {
    await _open(
      tester,
      FakeDetailTrailApi(
        error: const TrailApiException('No such trail', notFound: true),
      ),
    );

    expect(find.text('This trail is no longer available.'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(find.text('Report condition'), findsNothing);
  });

  testWidgets('a guest who taps Report condition is asked to log in', (
    tester,
  ) async {
    await _open(tester, FakeDetailTrailApi());

    await tester.tap(find.text('Report condition'));
    await tester.pumpAndSettle();
    expect(find.text('Log in to report conditions'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets(
    'a logged-in user reports a condition and sees the page refresh',
    (tester) async {
      final auth = AuthViewModel(
        api: FakeAuthApi(),
        store: InMemorySessionStore(testSession()),
      );
      await auth.restore();
      final trails = FakeDetailTrailApi();
      final reports = FakeReportApi();
      await _open(tester, trails, auth: auth, reportApi: reports);

      await tester.tap(find.text('Report condition'));
      await tester.pumpAndSettle();
      expect(find.text('What did you find?'), findsOneWidget);

      await tester.tap(find.text('Flooding'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Submit report'));
      await tester.pumpAndSettle();

      expect(reports.sent.single['trailId'], 9);
      expect(find.text('Thanks, report submitted'), findsOneWidget);
      expect(trails.calls, 2);
    },
  );
}
