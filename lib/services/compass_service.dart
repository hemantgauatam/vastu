import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Compass service that provides a smoothed magnetic-north heading in degrees [0, 360).
/// Heading increases clockwise: 0°=N, 90°=E, 180°=S, 270°=W.
class CompassService extends ChangeNotifier {
  static const double _deadbandDegrees = 0.65;
  static const double _notificationThresholdDegrees = 0.25;
  static const double _lowAccuracyThresholdDegrees = 20;

  double _heading = 0;
  double _rawHeading = 0;
  double? _accuracyDegrees;
  bool _supported = true;
  bool _hasHeading = false;
  StreamSubscription<CompassEvent>? _sub;
  bool _isStarted = false;

  double get heading => _heading;
  double get rawHeading => _rawHeading;
  double? get accuracyDegrees => _accuracyDegrees;
  bool get calibrationNeeded =>
      _accuracyDegrees != null &&
      _accuracyDegrees!.isFinite &&
      _accuracyDegrees! > _lowAccuracyThresholdDegrees;

  String get accuracyLabel {
    final accuracy = _accuracyDegrees;
    if (accuracy == null || !accuracy.isFinite) return 'Checking';
    if (accuracy <= 8) return 'High';
    if (accuracy <= _lowAccuracyThresholdDegrees) return 'Medium';
    return 'Low';
  }

  bool get supported => _supported;
  bool get isStarted => _isStarted;

  static double normalizeHeading(double value) =>
      (value % 360.0 + 360.0) % 360.0;

  static double shortestDelta(double from, double to) =>
      ((normalizeHeading(to) - normalizeHeading(from) + 540) % 360) - 180;

  /// Updates the heading from web controls when a magnetometer is unavailable.
  void setManualHeading(double value) {
    if (!kIsWeb || value.isNaN || value.isInfinite) return;
    _heading = normalizeHeading(value);
    _rawHeading = _heading;
    notifyListeners();
  }

  Future<void> start() async {
    if (_isStarted) return;
    _isStarted = true;

    // Browsers do not expose a reliable compass through flutter_compass.
    // The Compass screen provides drag and slider controls instead.
    if (kIsWeb) {
      _supported = false;
      notifyListeners();
      return;
    }

    try {
      final stream = FlutterCompass.events;
      if (stream == null) {
        _supported = false;
        notifyListeners();
        return;
      }

      _sub = stream.listen(
        (event) {
          try {
            final h = event.heading;
            if (h == null) {
              // Some devices return null when sensor is not ready
              return;
            }

            final normalized = normalizeHeading(h);

            // Clamp to valid range to prevent edge case issues
            if (normalized.isNaN || normalized.isInfinite) {
              return;
            }

            _rawHeading = normalized;
            final previousAccuracy = _accuracyDegrees;
            _accuracyDegrees = event.accuracy?.abs();
            final accuracyChanged = previousAccuracy == null
                ? _accuracyDegrees != null
                : _accuracyDegrees == null ||
                    (previousAccuracy - _accuracyDegrees!).abs() >= 1;

            if (!_hasHeading) {
              _hasHeading = true;
              _heading = normalized;
              notifyListeners();
              return;
            }

            // Ignore sensor noise while the phone is still, then use a
            // circular adaptive low-pass filter. Intentional turns remain
            // responsive while the Chakra no longer jitters around a bearing.
            final delta = shortestDelta(_heading, normalized);
            final magnitude = delta.abs();
            if (magnitude < _deadbandDegrees) {
              if (accuracyChanged) notifyListeners();
              return;
            }
            final alpha = switch (magnitude) {
              < 2 => 0.06,
              < 6 => 0.12,
              < 15 => 0.22,
              < 45 => 0.40,
              _ => 0.65,
            };
            final filtered = normalizeHeading(_heading + delta * alpha);
            if (shortestDelta(_heading, filtered).abs() >=
                    _notificationThresholdDegrees ||
                accuracyChanged) {
              _heading = filtered;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Kubar Vastu: Compass event error: $e');
          }
        },
        onError: (error) {
          debugPrint('Kubar Vastu: Compass stream error: $error');
          _supported = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Kubar Vastu: Failed to start compass: $e');
      _supported = false;
      _isStarted = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _isStarted = false;
    super.dispose();
  }
}
