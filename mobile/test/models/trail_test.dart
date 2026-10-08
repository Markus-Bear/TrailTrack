import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/trail.dart';

Map<String, dynamic> feature({
  Map<String, dynamic>? geometry,
  String? difficulty = 'Moderate',
  num? lengthKm = 4.4,
}) => {
  'type': 'Feature',
  'id': 19,
  'properties': {
    'name': 'Collins Bog Loop',
    'difficulty': difficulty,
    'lengthKm': lengthKm,
  },
  'geometry':
      geometry ??
      {
        'type': 'MultiLineString',
        'coordinates': [
          [
            [-7.35, 52.91],
            [-7.36, 52.92],
          ],
          [
            [-7.40, 52.95],
            [-7.41, 52.96],
          ],
        ],
      },
};

void main() {
  group('Trail.fromFeature', () {
    test('parses attributes', () {
      final trail = Trail.fromFeature(feature());
      expect(trail.id, 19);
      expect(trail.name, 'Collins Bog Loop');
      expect(trail.difficulty, Difficulty.moderate);
      expect(trail.lengthKm, 4.4);
    });

    test('parses a MultiLineString into separate lines', () {
      final trail = Trail.fromFeature(feature());
      expect(trail.lines, hasLength(2));
      expect(trail.lines[1], hasLength(2));
    });

    test('swaps GeoJSON [lon, lat] into LatLng(lat, lon)', () {
      final trail = Trail.fromFeature(feature());
      expect(trail.lines.first.first, const LatLng(52.91, -7.35));
    });

    test('parses a LineString as a single line', () {
      final trail = Trail.fromFeature(
        feature(
          geometry: {
            'type': 'LineString',
            'coordinates': [
              [-7.35, 52.91],
              [-7.36, 52.92],
            ],
          },
        ),
      );
      expect(trail.lines, hasLength(1));
    });

    test('rejects non-line geometry', () {
      expect(
        () => Trail.fromFeature(
          feature(
            geometry: {
              'type': 'Point',
              'coordinates': [-7.35, 52.91],
            },
          ),
        ),
        throwsFormatException,
      );
    });

    test('allows a missing length', () {
      expect(Trail.fromFeature(feature(lengthKm: null)).lengthKm, isNull);
    });
  });

  group('Difficulty.parse', () {
    test('matches the register values case-insensitively', () {
      expect(Difficulty.parse('Easy'), Difficulty.easy);
      expect(Difficulty.parse('challenging'), Difficulty.challenging);
    });

    test('falls back to unknown', () {
      expect(Difficulty.parse('Strenuous'), Difficulty.unknown);
      expect(Difficulty.parse(null), Difficulty.unknown);
    });
  });

  test('listFromFeatureCollection parses every feature', () {
    final trails = Trail.listFromFeatureCollection({
      'type': 'FeatureCollection',
      'features': [feature(), feature()],
    });
    expect(trails, hasLength(2));
  });
}
