import 'package:flutter/foundation.dart';

import '../models/condition_report.dart';
import '../services/report_api.dart';
import 'auth_view_model.dart';

/// The report form's state: the chosen condition and severity, and sending
/// the report.
class ReportViewModel extends ChangeNotifier {
  ReportViewModel({
    required this._api,
    required this._auth,
    required this.trailId,
  });

  final ReportApi _api;
  final AuthViewModel _auth;
  final int trailId;

  ConditionType? _conditionType;
  Severity _severity = Severity.moderate;
  bool _busy = false;
  String? _error;
  bool _sessionExpired = false;

  /// Made on the first attempt and kept for retries, so a report sent again
  /// after a dropped connection is not stored twice.
  String? _clientRef;

  ConditionType? get conditionType => _conditionType;
  Severity get severity => _severity;
  bool get busy => _busy;

  /// Why the last attempt failed, or null.
  String? get error => _error;

  /// Whether the user must log in again before the report can be sent.
  bool get sessionExpired => _sessionExpired;

  /// Clear reports have no severity.
  bool get needsSeverity =>
      _conditionType != null && _conditionType != ConditionType.clear;

  bool get canSubmit => _conditionType != null && !_busy;

  void selectCondition(ConditionType type) {
    _conditionType = type;
    _error = null;
    notifyListeners();
  }

  void selectSeverity(Severity severity) {
    _severity = severity;
    notifyListeners();
  }

  /// Sends the report.
  ///
  /// @param note optional extra detail
  /// @return the stored report, or null if it could not be sent
  Future<ConditionReport?> submit({String? note}) async {
    final type = _conditionType;
    final token = _auth.accessToken;
    if (type == null) return null;
    if (token == null) {
      _sessionExpired = true;
      _error = 'Please log in to report conditions.';
      notifyListeners();
      return null;
    }

    _busy = true;
    _error = null;
    _sessionExpired = false;
    notifyListeners();
    _clientRef ??= newClientRef();
    try {
      return await _api.submit(
        trailId: trailId,
        token: token,
        conditionType: type,
        severity: needsSeverity ? _severity : null,
        note: note,
        clientRef: _clientRef!,
      );
    } on ReportApiException catch (e) {
      _error = e.message;
      if (e.sessionExpired) {
        _sessionExpired = true;
        await _auth.logout();
      }
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
