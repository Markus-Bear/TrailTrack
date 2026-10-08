import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_site.dart';

Trail trail(
  int id,
  String name, {
  String? site,
  String? siteName,
  double? km,
  WaymarkColour colour = WaymarkColour.unknown,
}) => Trail(
  id: id,
  name: name,
  difficulty: Difficulty.moderate,
  lengthKm: km,
  lines: const [
    [LatLng(53.0, -7.1), LatLng(53.01, -7.11)],
  ],
  waymarkColour: colour,
  siteId: site,
  siteName: siteName,
);

void main() {
  group('Trail', () {
    test('parses waymark colour, site and trailhead from the API', () {
      final t = Trail.fromFeature({
        'id': 21,
        'properties': {
          'name': 'Oughaval Woods - Mass Rock Walk',
          'difficulty': 'Moderate',
          'lengthKm': 2.8,
          'waymarkColour': 'blue',
          'siteId': 'site-7',
          'siteName': 'Oughaval Woods',
          'trailhead': [-7.1271, 53.0035],
        },
        'geometry': {
          'type': 'LineString',
          'coordinates': [
            [-7.12, 53.0],
            [-7.13, 53.01],
          ],
        },
      });
      expect(t.waymarkColour, WaymarkColour.blue);
      expect(t.siteId, 'site-7');
      expect(t.trailhead, const LatLng(53.0035, -7.1271));
      expect(t.shortName, 'Mass Rock Walk');
    });

    test('a trail without a site is its own site', () {
      final t = trail(5, 'Brittas Forest Loop');
      expect(t.siteId, 'trail-5');
      expect(t.shortName, 'Brittas Forest Loop');
    });

    test('keeps the full name when it has no "site - " prefix', () {
      final t = trail(
        1,
        'Durrow Leafy Loop Long',
        siteName: 'Durrow Leafy Loop',
      );
      expect(t.shortName, 'Durrow Leafy Loop Long');
    });
  });

  group('TrailSite.group', () {
    test('groups trails by site, longest route first', () {
      final sites = TrailSite.group([
        trail(1, 'O - Beech Way Walk', site: 's1', siteName: 'O', km: 2),
        trail(2, 'Slieve Bloom Way', site: 's2', km: 74),
        trail(
          3,
          'O - Cobbler\'s Castle Walk',
          site: 's1',
          siteName: 'O',
          km: 6,
        ),
      ]);
      expect(sites, hasLength(2));
      expect(sites.first.name, 'O');
      expect(sites.first.routes.map((r) => r.id), [3, 1]);
      expect(sites.first.hasSeveralRoutes, isTrue);
      expect(sites.last.hasSeveralRoutes, isFalse);
    });
  });
}
