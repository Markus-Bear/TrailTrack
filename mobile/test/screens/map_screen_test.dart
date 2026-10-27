import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/screens/map_screen.dart';
import 'package:trailtrack/services/location_service.dart';
import 'package:trailtrack/services/trail_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';
import 'package:trailtrack/widgets/map_overlays.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_search.dart';

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

Future<void> _pumpMap(
  WidgetTester tester,
  TrailApi api, {
  AuthViewModel? auth,
  LocationService? location,
}) => tester.pumpWidget(
  withAuth(
    MaterialApp(
      home: MapScreen(api: api, location: location),
    ),
    auth: auth,
  ),
);

void main() {
  testWidgets(
    'shows an error with Retry when trails fail to load, and retries',
    (tester) async {
      final api = _FlakyTrailApi();
      await _pumpMap(tester, api);
      await tester.pump();

      expect(find.textContaining('Could not load trails'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(api.calls, 2);
      expect(find.textContaining('Could not load trails'), findsNothing);
    },
  );

  testWidgets('shows the map data attribution, and no legend without trails', (
    tester,
  ) async {
    await _pumpMap(tester, _FlakyTrailApi());
    await tester.pump();

    expect(find.textContaining('OpenStreetMap contributors'), findsOneWidget);
    expect(find.textContaining('Sport Ireland (CC BY 4.0)'), findsOneWidget);
    expect(find.text('Colour of the trail signs'), findsNothing);
  });

  testWidgets(
    'tapping a trail highlights it and shows its card, tapping the map clears it',
    (tester) async {
      // After fitting, the vertical trail runs through the centre of the map
      // and the horizontal one along the bottom of the fitted area.
      final across = _trail(1, const [LatLng(53.0, -7.4), LatLng(53.2, -7.4)]);
      final edge = _trail(2, const [LatLng(53.0, -7.6), LatLng(53.0, -7.2)]);
      await _pumpMap(tester, _FakeTrailApi([across, edge]));
      await tester.pump();
      await tester.pump();

      expect(find.text('Colour of the trail signs'), findsOneWidget);

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

  testWidgets('tapping a site pin shows its routes, and a chip selects one', (
    tester,
  ) async {
    Trail route(int id, String name, LatLng end) => Trail(
      id: id,
      name: 'Oughaval Woods - $name',
      difficulty: Difficulty.moderate,
      lengthKm: id.toDouble(),
      lines: [
        [const LatLng(53.0, -7.1), end],
      ],
      siteId: 'site-7',
      siteName: 'Oughaval Woods',
    );
    final api = _FakeTrailApi([
      route(1, 'Beech Way Walk', const LatLng(53.1, -7.0)),
      route(2, 'Mass Rock Walk', const LatLng(53.2, -7.4)),
    ]);
    await _pumpMap(tester, api);
    await tester.pump();
    await tester.pump();

    await tester.tap(find.byType(SitePin));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('2 routes from this trailhead'), findsOneWidget);
    expect(find.byType(SitePin), findsNothing);

    await tester.tap(find.text('Beech Way Walk'));
    await tester.pump();

    expect(find.text('Moderate | 1.0 km'), findsOneWidget);
  });

  testWidgets(
    'tapping a path shared by two routes asks which route was meant',
    (tester) async {
      // Both routes run along the same line through the centre of the map.
      const shared = [LatLng(53.0, -7.4), LatLng(53.2, -7.4)];
      final first = _trail(1, shared);
      final second = _trail(2, shared);
      await _pumpMap(tester, _FakeTrailApi([first, second]));
      await tester.pump();
      await tester.pump();

      await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
      await tester.pumpAndSettle();

      expect(find.text('Which route?'), findsOneWidget);

      await tester.tap(find.text('Trail 2'));
      await tester.pumpAndSettle();

      expect(find.text('Which route?'), findsNothing);
      expect(_drawnPolylines(tester).last.hitValue, second);
      expect(find.text('Easy | 1.0 km'), findsOneWidget);
    },
  );

  testWidgets('a guest sees Log in on the map, which opens the login screen', (
    tester,
  ) async {
    await _pumpMap(tester, _FakeTrailApi(const []));
    await tester.pump();

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets('a logged-in user can log out from the account menu', (
    tester,
  ) async {
    final store = InMemorySessionStore(testSession());
    final auth = AuthViewModel(api: FakeAuthApi(), store: store);
    await auth.restore();
    await _pumpMap(tester, _FakeTrailApi(const []), auth: auth);
    await tester.pump();

    expect(find.text('Log in'), findsNothing);
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('hiker@example.com'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Log in'), findsOneWidget);
    expect(store.saved, isNull);
  });

  testWidgets('the location button marks and centres on the phone position', (
    tester,
  ) async {
    final location = FakeLocationService(
      const LocationFound(glenbarrowCarPark),
    );
    await _pumpMap(tester, _FakeTrailApi(const []), location: location);
    await tester.pump();
    expect(find.byWidgetPredicate((w) => w is CircleLayer), findsNothing);

    await tester.tap(find.byTooltip('Show my location'));
    await tester.pump();
    await tester.pump();

    expect(location.calls, 1);
    final dot = tester.widget<CircleLayer>(
      find.byWidgetPredicate((w) => w is CircleLayer),
    );
    expect(dot.circles.single.point, glenbarrowCarPark);
  });

  testWidgets('without a position the location button says why', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      _FakeTrailApi(const []),
      location: FakeLocationService(
        const LocationUnavailable('Location permission was not given.'),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Show my location'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Location permission was not given.'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is CircleLayer), findsNothing);
  });
}
