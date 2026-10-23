import 'package:flutter/foundation.dart';

import '../models/trail_detail.dart';
import '../services/trail_api.dart';

/// Loads and holds one trail's detail page.
class TrailDetailViewModel extends ChangeNotifier {
  TrailDetailViewModel({required this._api, required this.trailId});

  final TrailApi _api;
  final int trailId;

  TrailDetail? _detail;
  bool _loading = false;
  String? _error;
  bool _notFound = false;

  TrailDetail? get detail => _detail;
  bool get loading => _loading;

  /// Why loading failed, or null.
  String? get error => _error;

  /// Whether the trail no longer exists, so retrying will not help.
  bool get notFound => _notFound;

  /// Loads the trail, or reloads it to pick up new reports.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _api.fetchTrailDetail(trailId);
      _notFound = false;
    } on TrailApiException catch (e) {
      _notFound = e.notFound;
      _error = e.notFound
          ? 'This trail is no longer available.'
          : 'Could not load this trail. Check your connection and try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
