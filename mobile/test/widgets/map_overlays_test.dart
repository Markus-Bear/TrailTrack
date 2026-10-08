import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_site.dart';
import 'package:trailtrack/widgets/map_overlays.dart';

Trail _route(int id, String name, double km) => Trail(
  id: id,
  name: 'Oughaval Woods - $name',
  difficulty: Difficulty.moderate,
  lengthKm: km,
  lines: const [
    [LatLng(53.0, -7.1), LatLng(53.01, -7.11)],
  ],
  siteId: 'site-7',
  siteName: 'Oughaval Woods',
);

final _site = TrailSite.group([
  _route(1, 'Beech Way Walk', 2),
  _route(2, 'Mass Rock Walk', 2.8),
]).single;

Future<void> _pump(WidgetTester tester, Widget child) =>
    tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

void main() {
  testWidgets('card for a whole site says how many routes start there', (
    tester,
  ) async {
    await _pump(
      tester,
      SelectionCard(site: _site, selected: null, onSelectRoute: (_) {}),
    );

    expect(find.text('Oughaval Woods'), findsOneWidget);
    expect(find.text('2 routes from this trailhead'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(2));
  });

  testWidgets('card for a route shows its short name and summary', (
    tester,
  ) async {
    await _pump(
      tester,
      SelectionCard(
        site: _site,
        selected: _site.routes.first,
        onSelectRoute: (_) {},
      ),
    );

    expect(find.text('Moderate | 2.8 km'), findsOneWidget);
    expect(find.text('Mass Rock Walk'), findsNWidgets(2));
  });

  testWidgets('tapping a route chip selects that route', (tester) async {
    Trail? chosen;
    await _pump(
      tester,
      SelectionCard(
        site: _site,
        selected: null,
        onSelectRoute: (r) => chosen = r,
      ),
    );

    await tester.tap(find.text('Beech Way Walk'));

    expect(chosen?.id, 1);
  });

  testWidgets('site pin shows the number of routes', (tester) async {
    await _pump(tester, SitePin(site: _site, onTap: () {}));

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('legend explains sign colours and National Waymarked Ways', (
    tester,
  ) async {
    await _pump(tester, const RouteLegend());

    expect(find.text('Colour of the trail signs'), findsOneWidget);
    expect(find.text('National Waymarked Way'), findsOneWidget);
  });
}
