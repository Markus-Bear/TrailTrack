import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/trail.dart';

/// Thrown when trails cannot be loaded from the backend.
class TrailApiException implements Exception {
  const TrailApiException(this.message);

  final String message;

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
}
