import 'package:flutter/foundation.dart';
import '../models/addon_source_model.dart';

/// Audio Route Types recognized by AuraBeat for BitChord Lossless Output Gating.
enum AudioRouteType {
  wiredHeadphones('Wired Headphones (3.5mm)', true),
  usbDac('USB-C DAC / Audio Interface', true),
  lineOut('Line Out / Aux', true),
  hdmi('HDMI / eARC Digital Output', true),
  dock('Digital Audio Dock', true),
  bluetoothLdac('Bluetooth LDAC (High-Res 990 kbps)', true),
  bluetoothLhdc('Bluetooth LHDC (High-Res 900 kbps)', true),
  bluetoothAptxLossless('Qualcomm aptX Lossless', true),
  bluetoothLossy('Bluetooth (AAC / SBC / aptX / LC3)', false),
  phoneSpeaker('Internal Phone Speaker', false),
  unknown('Unknown / Detached Route', false);

  final String label;
  final bool isLosslessQualified;
  const AudioRouteType(this.label, this.isLosslessQualified);
}

/// Lossless Output Gate Manager (BitChord checkValidLossless protocol)
///
/// Implements BitChord's strict lossless hardware output gating:
/// If an add-on source specifies `checkValidLossless: 1`, requests (search, stream)
/// are gated unless the active audio route is certified lossless-capable.
class LosslessOutputManager extends ChangeNotifier {
  static final LosslessOutputManager instance = LosslessOutputManager._internal();

  AudioRouteType _currentRoute = AudioRouteType.usbDac; // Default for audiophile testing
  final bool _hardwareDetectionEnabled = true;

  LosslessOutputManager._internal();

  /// Factory for testing or custom route injection
  factory LosslessOutputManager.custom(AudioRouteType initialRoute) {
    final m = LosslessOutputManager._internal();
    m._currentRoute = initialRoute;
    return m;
  }

  AudioRouteType get currentRoute => _currentRoute;

  /// Whether current active audio route meets BitChord lossless requirements
  bool get isLosslessQualified => _currentRoute.isLosslessQualified;

  bool get hardwareDetectionEnabled => _hardwareDetectionEnabled;

  /// Switch the active route (e.g. from system device listener or UI selector)
  void setAudioRoute(AudioRouteType route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      notifyListeners();
    }
  }

  /// Check whether an add-on source is allowed to be queried for search/stream
  /// according to BitChord's `checkValidLossless` gate rule.
  bool shouldAllowGatedSource(AddonSourceConfig source) {
    if (!source.checkValidLossless) {
      // Source does not enforce lossless output gating
      return true;
    }
    // Gated source requires a qualifying lossless output
    return isLosslessQualified;
  }

  /// User-facing status string for an add-on source regarding lossless output gating
  String? getGatedStatusMessage(AddonSourceConfig source) {
    if (source.checkValidLossless && !isLosslessQualified) {
      return 'Needs a lossless output';
    }
    return null;
  }
}
