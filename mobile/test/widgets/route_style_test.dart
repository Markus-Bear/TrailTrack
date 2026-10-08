import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_site.dart';
import 'package:trailtrack/widgets/route_style.dart';

Trail _route(
  WaymarkColour colour, {
  int id = 1,
  String site = 's',
  double? lengthKm = 2.8,
}) => Trail(
  id: id,
  name: 'Mass Rock Walk',
  difficulty: Difficulty.moderate,
  lengthKm: lengthKm,
  lines: const [],
  waymarkColour: colour,
  siteId: site,
);

/// Colour of a route that is the only one at its site.
Color _colourAlone(WaymarkColour colour) {
  final route = _route(colour);
  return routeColour(route, TrailSite.group([route]).single);
}

void main() {
  test('routes are drawn in the colour of their trail signs', () {
    expect(_colourAlone(WaymarkColour.blue), const Color(0xFF1565C0));
    expect(_colourAlone(WaymarkColour.red), const Color(0xFFC62828));
  });

  test('each known sign colour gets its own line colour', () {
    final known = WaymarkColour.values.where((c) => c != WaymarkColour.unknown);
    expect(known.map(_colourAlone).toSet(), hasLength(known.length));
  });

  test('gives unrecorded routes at one site different fallback colours', () {
    final a = _route(WaymarkColour.unknown, id: 1, lengthKm: 4);
    final b = _route(WaymarkColour.unknown, id: 2, lengthKm: 2);
    final site = TrailSite.group([a, b]).single;
    expect(routeColour(a, site), isNot(routeColour(b, site)));
  });

  test('only yellow-waymarked routes are National Waymarked Ways', () {
    expect(isNationalWay(_route(WaymarkColour.yellow)), isTrue);
    expect(isNationalWay(_route(WaymarkColour.green)), isFalse);
  });

  test('summary shows difficulty and length, leaving out a missing length', () {
    expect(routeSummary(_route(WaymarkColour.blue)), 'Moderate | 2.8 km');
    expect(
      routeSummary(_route(WaymarkColour.blue, lengthKm: null)),
      'Moderate',
    );
  });
}
