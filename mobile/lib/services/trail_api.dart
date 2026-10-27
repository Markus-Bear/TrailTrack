import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../config.dart';
import '../models/trail.dart';
import '../models/trail_detail.dart';
import '../models/trail_search_result.dart';

/// Thrown when trails cannot be loaded from the backend.
class TrailApiException implements Exception {
  const TrailApiException(this.message, {this.notFound = false});

  final String message;

  /// Whether the backend has no trail with the requested id.
  final bool notFound;

  @override
  String toString() => 'TrailApiException: $message';
}

/// Client for the backend's trail endpoints.
class TrailApi {
  /// @param baseUrl backend base URL, defaults to [apiBaseUrl]
  TrailApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  /// Fetches every trail for display on the map.
  ///
  /// @return the trails, ordered by name
  /// @throws TrailApiException if the backend cannot be reached or responds
  ///         with an error
  Future<List<Trail>> fetchTrails() async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/api/trails'))
          .timeout(const Duration(seconds: 15));
    } on Exception catch (e) {
      throw TrailApiException('Could not reach the server ($e)');
    }
    if (response.statusCode != 200) {
      throw TrailApiException('Server responded with ${response.statusCode}');
    }
    return Trail.listFromFeatureCollection(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Fetches one trail's details and recent condition reports.
  ///
  /// @param id the trail's id
  /// @return the trail detail
  /// @throws TrailApiException if the backend cannot be reached, responds
  ///         with an error, or has no such trail (then [TrailApiException.notFound])
  Future<TrailDetail> fetchTrailDetail(int id) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/api/trails/$id'))
          .timeout(const Duration(seconds: 15));
    } on Exception catch (e) {
      throw TrailApiException('Could not reach the server ($e)');
    }
    if (response.statusCode == 404) {
      throw const TrailApiException('No such trail', notFound: true);
    }
    if (response.statusCode != 200) {
      throw TrailApiException('Server responded with ${response.statusCode}');
    }
    return TrailDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Searches trails by name and, with a position, by distance. The position
  /// is sent only with this request.
  ///
  /// @param query text the trail name must contain, or null for any name
  /// @param near the searcher's position, or null to search by name only
  /// @param radiusKm how far from [near] to look
  /// @return matching trails, nearest first with a position, otherwise A to Z
  /// @throws TrailApiException if the backend cannot be reached or responds
  ///         with an error
  Future<List<TrailSearchResult>> searchTrails({
    String? query,
    LatLng? near,
    double? radiusKm,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/trails/search').replace(
      queryParameters: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (near != null) ...{
          'lat': '${near.latitude}',
          'lon': '${near.longitude}',
          if (radiusKm != null) 'radiusKm': '$radiusKm',
        },
      },
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(const Duration(seconds: 15));
    } on Exception catch (e) {
      throw TrailApiException('Could not reach the server ($e)');
    }
    if (response.statusCode != 200) {
      throw TrailApiException('Server responded with ${response.statusCode}');
    }
    return [
      for (final r in jsonDecode(response.body) as List)
        TrailSearchResult.fromJson(r as Map<String, dynamic>),
    ];
  }
}
