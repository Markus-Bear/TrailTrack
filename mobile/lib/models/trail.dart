import 'package:latlong2/latlong.dart';

/// Trail difficulty, as graded by the Sport Ireland register.
enum Difficulty {
  easy('Easy'),
  moderate('Moderate'),
  challenging('Challenging'),
  unknown('Unknown');

  const Difficulty(this.label);

  final String label;

  /// Parses a difficulty from the register's text value.
  ///
  /// @param value the register's difficulty, e.g. "Moderate"
  /// @return the matching difficulty, or [Difficulty.unknown]
  static Difficulty parse(String? value) {
    final normalised = value?.trim().toLowerCase();
    return Difficulty.values.firstWhere(
      (d) => d.name == normalised,
      orElse: () => Difficulty.unknown,
    );
  }
}

/// Colour of a route's trail signs, as recorded in the Sport Ireland register.
enum WaymarkColour {
  green,
  blue,
  red,
  purple,
  yellow,
  orange,
  unknown;

  /// Parses the backend's colour name, e.g. "blue".
  ///
  /// @param value the colour name
  /// @return the matching colour, or [WaymarkColour.unknown]
  static WaymarkColour parse(String? value) => WaymarkColour.values.firstWhere(
    (c) => c.name == value?.trim().toLowerCase(),
    orElse: () => WaymarkColour.unknown,
  );
}

/// A trail as shown on the map: display attributes plus its route.
class Trail {
  const Trail({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.lengthKm,
    required this.lines,
    this.waymarkColour = WaymarkColour.unknown,
    String? siteId,
    String? siteName,
    this.trailhead,
  }) : siteId = siteId ?? 'trail-$id',
       siteName = siteName ?? name;

  final int id;
  final String name;
  final Difficulty difficulty;
  final double? lengthKm;

  /// The route as one or more lines. Some trails have disconnected sections.
  final List<List<LatLng>> lines;

  /// Colour of the route's trail signs.
  final WaymarkColour waymarkColour;

  /// Identifies the site (trailhead) the route starts from. Routes from one
  /// car park share it.
  final String siteId;

  /// Display name of the site, e.g. "Oughaval Woods".
  final String siteName;

  /// Official start point of the route, if the register records one.
  final LatLng? trailhead;

  /// The route name without its site prefix, e.g. "Mass Rock Walk" rather
  /// than "Oughaval Woods - Mass Rock Walk".
  String get shortName => name.startsWith('$siteName - ')
      ? name.substring(siteName.length + 3)
      : name;

  /// Parses a trail from a GeoJSON Feature returned by `GET /api/trails`.
  ///
  /// @param feature the GeoJSON Feature
  /// @return the trail
  /// @throws FormatException if the geometry is not a line
  factory Trail.fromFeature(Map<String, dynamic> feature) {
    final properties = feature['properties'] as Map<String, dynamic>;
    return Trail(
      id: (feature['id'] as num).toInt(),
      // Some register names end with a stray space.
      name: (properties['name'] as String).trim(),
      difficulty: Difficulty.parse(properties['difficulty'] as String?),
      lengthKm: (properties['lengthKm'] as num?)?.toDouble(),
      lines: _parseLines(feature['geometry'] as Map<String, dynamic>),
      waymarkColour: WaymarkColour.parse(
        properties['waymarkColour'] as String?,
      ),
      siteId: properties['siteId'] as String?,
      siteName: properties['siteName'] as String?,
      trailhead: _parsePosition(properties['trailhead'] as List?),
    );
  }

  static LatLng? _parsePosition(List? position) => position == null
      ? null
      : LatLng(
          (position[1] as num).toDouble(),
          (position[0] as num).toDouble(),
        );

  /// Parses every feature in a GeoJSON FeatureCollection.
  ///
  /// @param collection the GeoJSON FeatureCollection
  /// @return one trail per feature
  static List<Trail> listFromFeatureCollection(
    Map<String, dynamic> collection,
  ) {
    return (collection['features'] as List)
        .map((f) => Trail.fromFeature(f as Map<String, dynamic>))
        .toList();
  }

  static List<List<LatLng>> _parseLines(Map<String, dynamic> geometry) {
    final coordinates = geometry['coordinates'] as List;
    switch (geometry['type']) {
      case 'LineString':
        return [_parseLine(coordinates)];
      case 'MultiLineString':
        return coordinates.map((line) => _parseLine(line as List)).toList();
      default:
        throw FormatException(
          'Unsupported trail geometry: ${geometry['type']}',
        );
    }
  }

  // GeoJSON positions are [longitude, latitude], the reverse of LatLng.
  static List<LatLng> _parseLine(List positions) {
    return positions.map((p) {
      final position = p as List;
      return LatLng(
        (position[1] as num).toDouble(),
        (position[0] as num).toDouble(),
      );
    }).toList();
  }
}
