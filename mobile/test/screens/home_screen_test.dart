import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_search_result.dart';
import 'package:trailtrack/screens/home_screen.dart';
import 'package:trailtrack/services/location_service.dart';
import 'package:trailtrack/services/trail_api.dart';
import 'package:trailtrack/view_models/auth_view_model.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_search.dart';

/// Counts how often the map loads its trails.
class _CountingTrailApi extends TrailApi {
  int mapLoads = 0;

  @override
  Future<List<Trail>> fetchTrails() async {
    mapLoads++;
    return const [];
  }

  @override
  Future<List<TrailSearchResult>> searchTrails({
    String? query,
    LatLng? near,
    double? radiusKm,
  }) async => [searchResult(9, 'Glenbarrow - Waterfall Loop')];
}

Future<_CountingTrailApi> _open(
  WidgetTester tester, {
  AuthViewModel? auth,
}) async {
  final api = _CountingTrailApi();
  await tester.pumpWidget(
    withAuth(
      MaterialApp(
        home: HomeScreen(
          api: api,
          location: FakeLocationService(const LocationFound(glenbarrowCarPark)),
        ),
      ),
      auth: auth,
    ),
  );
  await tester.pumpAndSettle();
  return api;
}

Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void main() {
  testWidgets('the tabs switch screens without reloading the map', (
    tester,
  ) async {
    final api = await _open(tester);
    expect(find.byTooltip('Show my location'), findsOneWidget);

    await tester.tap(_tab('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Glenbarrow - Waterfall Loop'), findsOneWidget);

    await tester.tap(_tab('Map'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Show my location'), findsOneWidget);
    expect(api.mapLoads, 1);
  });

  testWidgets('the map search button opens the Search tab', (tester) async {
    await _open(tester);

    await tester.tap(find.byTooltip('Search trails'));
    await tester.pumpAndSettle();

    expect(find.text('Search by name'), findsOneWidget);
  });

  testWidgets('a guest profile offers to log in or create an account', (
    tester,
  ) async {
    await _open(tester);

    await tester.tap(_tab('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('You are browsing as a guest'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  testWidgets(
    'a logged-in profile shows the account, and Log out returns to the map',
    (tester) async {
      final store = InMemorySessionStore(testSession());
      final auth = AuthViewModel(api: FakeAuthApi(), store: store);
      await auth.restore();
      await _open(tester, auth: auth);

      await tester.tap(_tab('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Markus'), findsOneWidget);
      expect(find.text('hiker@example.com'), findsOneWidget);

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isFalse);
      expect(store.saved, isNull);
      expect(find.byTooltip('Show my location'), findsOneWidget);

      await tester.tap(_tab('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('You are browsing as a guest'), findsOneWidget);
    },
  );
}
