import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/screens/report_screen.dart';
import 'package:trailtrack/services/report_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_report_api.dart';

/// Opens the form on top of a home page and returns what it closed with.
Future<List<ConditionReport?>> _open(WidgetTester tester, ReportApi api) async {
  // A phone-sized screen (360 x 800), so the whole form fits as on a device.
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final results = <ConditionReport?>[];
  final auth = AuthViewModel(
    api: FakeAuthApi(),
    store: InMemorySessionStore(testSession()),
  );
  await auth.restore();
  await tester.pumpWidget(
    withAuth(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => results.add(
                await Navigator.of(context).push<ConditionReport>(
                  MaterialPageRoute(
                    builder: (_) => ReportScreen(
                      trailId: 9,
                      trailName: 'Glenbarrow - Waterfall Loop',
                      api: api,
                    ),
                  ),
                ),
              ),
              child: const Text('Home'),
            ),
          ),
        ),
      ),
      auth: auth,
    ),
  );
  await tester.tap(find.text('Home'));
  await tester.pumpAndSettle();
  return results;
}

Finder get _submit => find.widgetWithText(FilledButton, 'Submit report');

void main() {
  testWidgets(
    'shows a tile for every condition and starts with nothing chosen',
    (tester) async {
      await _open(tester, FakeReportApi());

      for (final type in ConditionType.values) {
        expect(find.text(type.label), findsOneWidget);
      }
      expect(tester.widget<FilledButton>(_submit).onPressed, isNull);
      expect(find.text('How bad is it?'), findsNothing);
    },
  );

  testWidgets('choosing Clear hides the severity choice', (tester) async {
    await _open(tester, FakeReportApi());

    await tester.tap(find.text('Mud'));
    await tester.pump();
    expect(find.text('How bad is it?'), findsOneWidget);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('How bad is it?'), findsNothing);
  });

  testWidgets('a quick report is just a tile, then Submit', (tester) async {
    final api = FakeReportApi();
    final results = await _open(tester, api);

    await tester.tap(find.text('Fallen tree'));
    await tester.pump();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(api.sent.single['conditionType'], ConditionType.fallenTree);
    expect(api.sent.single['severity'], Severity.moderate);
    expect(results.single?.id, 50);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('with no connection the form stays open and can be sent again', (
    tester,
  ) async {
    final api = FakeReportApi(
      errors: [const ReportApiException('No connection, try again.')],
    );
    await _open(tester, api);

    await tester.tap(find.text('Mud'));
    await tester.pump();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('No connection, try again.'), findsOneWidget);
    expect(find.text('Report condition'), findsOneWidget);

    await tester.tap(_submit);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('an expired login offers to log in again', (tester) async {
    await _open(
      tester,
      FakeReportApi(
        errors: [
          const ReportApiException(
            'Your login has expired. Please log in again.',
            sessionExpired: true,
          ),
        ],
      ),
    );

    await tester.tap(find.text('Mud'));
    await tester.pump();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(
      find.text('Your login has expired. Please log in again.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
  });
}
