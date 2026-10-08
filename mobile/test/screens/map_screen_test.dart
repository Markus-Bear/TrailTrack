import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
