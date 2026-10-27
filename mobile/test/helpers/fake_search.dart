import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:trailtrack/models/condition_report.dart';
import 'package:trailtrack/models/trail.dart';
import 'package:trailtrack/models/trail_search_result.dart';
import 'package:trailtrack/services/location_service.dart';
import 'package:trailtrack/services/trail_api.dart';

TrailSearchResult searchResult(int id, String name, {double? distanceKm}) =>
    TrailSearchResult(
      id: id,
      name: name,
      difficulty: Difficulty.moderate,
      lengthKm: 3.2,
      distanceKm: distanceKm,
      latestReport: id == 9
          ? ConditionReport(
              id: 3,
              conditionType: ConditionType.mud,
              severity: Severity.moderate,
              note: null,
              reportedAt: DateTime.now(),
            )
          : null,
    );

/// Records each search and answers with [results].
class FakeSearchTrailApi extends TrailApi {
  FakeSearchTrailApi([List<TrailSearchResult>? results])
    : results = results ?? [searchResult(9, 'Glenbarrow - Waterfall Loop')];

  List<TrailSearchResult> results;
  final searches = <({String? query, LatLng? near, double? radiusKm})>[];

  /// When set, searches wait for it before answering.
  Completer<void>? hold;

  @override
  Future<List<TrailSearchResult>> searchTrails({
    String? query,
    LatLng? near,
    double? radiusKm,
  }) async {
    searches.add((query: query, near: near, radiusKm: radiusKm));
    final answer = results;
    await hold?.future;
    return answer;
  }
}

/// Answers every request for the position with [result].
class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  LocationResult result;
  int calls = 0;

  @override
  Future<LocationResult> currentPosition() async {
    calls++;
    return result;
  }
}

const glenbarrowCarPark = LatLng(53.12272, -7.45026);
