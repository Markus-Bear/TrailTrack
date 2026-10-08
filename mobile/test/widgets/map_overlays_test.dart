import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/widgets/map_overlays.dart';

Trail _trail({double? lengthKm}) => Trail(
  id: 1,
  name: 'Glenbarrow Waterfall Loop',
  difficulty: Difficulty.moderate,
  lengthKm: lengthKm,
  lines: const [
    [LatLng(53.1, -7.5), LatLng(53.2, -7.5)],
  ],
);

Future<void> _pumpCard(WidgetTester tester, Trail trail) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: TrailCard(trail: trail)),
  ),
);

void main() {
  testWidgets('trail card shows the name, difficulty and length', (
    tester,
  ) async {
    await _pumpCard(tester, _trail(lengthKm: 4.25));

    expect(find.text('Glenbarrow Waterfall Loop'), findsOneWidget);
    expect(find.text('Moderate | 4.3 km'), findsOneWidget);
  });

  testWidgets('trail card leaves out the length when it is unknown', (
    tester,
  ) async {
    await _pumpCard(tester, _trail());

    expect(find.text('Moderate'), findsOneWidget);
  });
}
