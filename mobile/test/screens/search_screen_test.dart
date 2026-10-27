import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/screens/search_screen.dart';
import 'package:trailtrack/services/location_service.dart';
import 'package:trailtrack/services/trail_api.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_search.dart';

Future<void> _open(
  WidgetTester tester,
  TrailApi api, {
  LocationService? location,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    withAuth(
      MaterialApp(
        home: SearchScreen(
          api: api,
          location:
              location ??
              FakeLocationService(const LocationFound(glenbarrowCarPark)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lists trails A to Z with their latest condition', (
    tester,
  ) async {
    await _open(
      tester,
      FakeSearchTrailApi([
        searchResult(10, 'Glenbarrow - Eco Walk'),
        searchResult(9, 'Glenbarrow - Waterfall Loop'),
      ]),
    );

    expect(find.text('2 trails, A to Z'), findsOneWidget);
    expect(find.text('Mud, moderate'), findsOneWidget);
    expect(find.text('No recent reports'), findsOneWidget);
    expect(find.text('Moderate | 3.2 km'), findsNWidgets(2));
  });

  testWidgets('near me shows distances, radius choices and nearest first', (
    tester,
  ) async {
    final api = FakeSearchTrailApi([
      searchResult(9, 'Glenbarrow - Waterfall Loop', distanceKm: 0.08),
    ]);
    await _open(tester, api);

    await tester.tap(find.text('Near me'));
    await tester.pumpAndSettle();

    expect(find.text('1 trail, nearest first'), findsOneWidget);
    expect(find.text('Moderate | 3.2 km | 0.1 km away'), findsOneWidget);
    expect(find.text('10 km'), findsOneWidget);

    await tester.tap(find.text('5 km'));
    await tester.pumpAndSettle();
    expect(api.searches.last.radiusKm, 5);
  });

  testWidgets('with location refused it explains and still searches by name', (
    tester,
  ) async {
    await _open(
      tester,
      FakeSearchTrailApi(),
      location: FakeLocationService(
        const LocationUnavailable('Location permission was not given.'),
      ),
    );

    await tester.tap(find.text('Near me'));
    await tester.pumpAndSettle();

    expect(
      find.text('Location permission was not given. Searching by name only.'),
      findsOneWidget,
    );
    expect(find.text('Glenbarrow - Waterfall Loop'), findsOneWidget);
  });

  testWidgets('no results near me suggests a wider radius', (tester) async {
    final api = FakeSearchTrailApi();
    await _open(tester, api);
    api.results = const [];

    await tester.tap(find.text('Near me'));
    await tester.pumpAndSettle();

    expect(find.text('No trails found. Try a wider radius.'), findsOneWidget);
  });

  testWidgets('tapping a result opens its trail page', (tester) async {
    await _open(tester, FakeSearchTrailApi());

    await tester.tap(find.text('Glenbarrow - Waterfall Loop'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Report condition'), findsOneWidget);
  });
}
