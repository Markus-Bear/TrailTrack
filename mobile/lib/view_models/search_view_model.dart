import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/trail_search_result.dart';
import '../services/location_service.dart';
import '../services/trail_api.dart';

/// The search screen's state: the search text, "Near me" and its radius,
/// and the results.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({
    required this._api,
    required this._location,
    this.typingDelay = const Duration(milliseconds: 300),
  });

  /// The radius choices offered with "Near me", in kilometres.
  static const radiusOptions = [5.0, 10.0, 25.0];

  final TrailApi _api;
  final LocationService _location;

  /// How long typing must pause before the search runs.
  final Duration typingDelay;

  String _query = '';
  bool _nearMe = false;
  double _radiusKm = 10;
  List<TrailSearchResult> _results = const [];
  bool _resultsAreNearby = false;
  bool _loading = false;
  String? _error;
  String? _locationMessage;
  Timer? _typing;
  int _latestRequest = 0;

  /// Kept only in memory, for the searches made while the screen is open.
  LatLng? _position;

  String get query => _query;
  bool get nearMe => _nearMe;
  double get radiusKm => _radiusKm;
  List<TrailSearchResult> get results => _results;

  /// Whether the results on show came from a "Near me" search, so they are
  /// nearest first and have distances.
  bool get resultsAreNearby => _resultsAreNearby;
  bool get loading => _loading;
  String? get error => _error;

  /// Why "Near me" could not be used, or null.
  String? get locationMessage => _locationMessage;

  /// Called as the user types; searches once they pause.
  void setQuery(String query) {
    _query = query;
    _typing?.cancel();
    _typing = Timer(typingDelay, search);
  }

  /// Turns "Near me" on or off. Turning it on finds the phone's position,
  /// asking for permission the first time; if that fails, the search stays
  /// by name and [locationMessage] says why.
  Future<void> setNearMe(bool on) async {
    _locationMessage = null;
    if (!on) {
      _nearMe = false;
      _position = null;
      await search();
      return;
    }
    _nearMe = true;
    _loading = true;
    notifyListeners();
    final result = await _location.currentPosition();
    switch (result) {
      case LocationFound(:final position):
        _position = position;
      case LocationUnavailable(:final reason):
        _nearMe = false;
        _position = null;
        _locationMessage = '$reason Searching by name only.';
    }
    await search();
  }

  /// Changes the "Near me" radius and searches again.
  Future<void> setRadius(double km) async {
    _radiusKm = km;
    await search();
  }

  /// Runs the search with the current settings. Results from an older search
  /// that finishes late are ignored. While "Near me" is still finding the
  /// position, nothing is sent: [setNearMe] searches once it has it, with the
  /// text and radius chosen in the meantime.
  Future<void> search() async {
    _typing?.cancel();
    if (_nearMe && _position == null) return;
    final request = ++_latestRequest;
    _loading = true;
    _error = null;
    notifyListeners();
    final near = _nearMe ? _position : null;
    try {
      final results = await _api.searchTrails(
        query: _query,
        near: near,
        radiusKm: near == null ? null : _radiusKm,
      );
      if (request != _latestRequest) return;
      _results = results;
      _resultsAreNearby = near != null;
    } on TrailApiException {
      if (request != _latestRequest) return;
      _error = 'Could not search trails. Check your connection and try again.';
    } finally {
      if (request == _latestRequest) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _typing?.cancel();
    super.dispose();
  }
}
