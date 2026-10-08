import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/screens/map_screen.dart';
import 'package:trailtrack/services/trail_api.dart';

/// Fake API that fails the first call and succeeds after that.
class _FlakyTrailApi extends TrailApi {
  int calls = 0;

  @override
  Future<List<Trail>> fetchTrails() async {
    calls++;
    if (calls == 1) throw const TrailApiException('offline');
    return const [];
  }
}

class _FakeTrailApi extends TrailApi {
  _FakeTrailApi(this.trails);

  final List<Trail> trails;

  @override
  Future<List<Trail>> fetchTrails() async => trails;
}

Trail _trail(int id, List<LatLng> line) => Trail(
  id: id,
  name: 'Trail $id',
  difficulty: Difficulty.easy,
  lengthKm: 1,
  lines: [line],
);

List<Polyline<Trail>> _drawnPolylines(WidgetTester tester) => tester
    .widget<PolylineLayer<Trail>>(
      find.byWidgetPredicate((w) => w is PolylineLayer<Trail>),
    )
    .polylines;

void main() {
  testWidgets(
    'shows an error with Retry when trails fail to load, and retries',
    (tester) async {
      final api = _FlakyTrailApi();
      await tester.pumpWidget(MaterialApp(home: MapScreen(api: api)));
      await tester.pump();

      expect(find.textContaining('Could not load trails'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(api.calls, 2);
      expect(find.textContaining('Could not load trails'), findsNothing);
    },
  );

  testWidgets('shows the map data attribution', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: MapScreen(api: _FlakyTrailApi())),
    );
    await tester.pump();

    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(find.textContaining('Sport Ireland (CC BY 4.0)'), findsOneWidget);
  });

  testWidgets(
    'tapping a trail highlights it and shows its card, tapping the map clears it',
    (tester) async {
      // After fitting, the horizontal trail runs through the centre of the
      // map and the vertical one along its left edge.
      final across = _trail(1, const [LatLng(53.1, -7.6), LatLng(53.1, -7.2)]);
      final edge = _trail(2, const [LatLng(53.0, -7.6), LatLng(53.2, -7.6)]);
      await tester.pumpWidget(
        MaterialApp(home: MapScreen(api: _FakeTrailApi([across, edge]))),
      );
      await tester.pump();
      await tester.pump();

      final map = find.byType(FlutterMap);
      await tester.tapAt(tester.getCenter(map));
      await tester.pump(const Duration(milliseconds: 500));

      var drawn = _drawnPolylines(tester);
      expect(drawn.last.hitValue, across);
      expect(drawn.last.strokeWidth, greaterThan(drawn.first.strokeWidth));
      expect(drawn.first.color.a, lessThan(1));
      expect(find.text('Trail 1'), findsOneWidget);

      await tester.tapAt(tester.getTopRight(map) + const Offset(-100, 100));
      await tester.pump(const Duration(milliseconds: 500));

      drawn = _drawnPolylines(tester);
      expect(drawn.map((p) => p.strokeWidth).toSet(), hasLength(1));
      expect(drawn.every((p) => p.color.a == 1), isTrue);
      expect(find.text('Trail 1'), findsNothing);
    },
  );
}
