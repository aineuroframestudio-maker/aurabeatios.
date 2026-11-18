// Copyright (C) 2026 AuraBeat Project.
// AuraBeat Sub-Bass Enhancement Engine Facade.

import '../../audio_bridge.dart';
import 'sub_bass_config.dart';
import 'sub_bass_dsp.dart';

class SubBassEngine {
  static final SubBassEngine instance = SubBassEngine._internal();

  final SubBassDspEngine _dsp = SubBassDspEngine();
  SubBassConfiguration _config = const SubBassConfiguration();

  SubBassEngine._internal();

  SubBassDspEngine get dsp => _dsp;
  SubBassConfiguration get config => _config;
  bool get isEnabled => _config.enabled;

  /// Updates Sub-Bass Enhancement configuration and broadcasts to native and web platforms.
  void setConfiguration(SubBassConfiguration newConfig) {
    _config = newConfig;
    _dsp.updateConfiguration(newConfig);

    WebAudioBridge.setSubBassEnhancement(
      enabled: newConfig.enabled,
      intensity: newConfig.intensity,
      frequencyHz: newConfig.frequencyHz,
      outputLevelDb: newConfig.outputLevelDb,
      preset: newConfig.preset.displayName,
    );
  }

  /// Sets master enable/disable state.
  void setEnabled(bool enabled) {
    setConfiguration(_config.copyWith(enabled: enabled));
  }

  /// Sets sub-bass intensity (0.0 to 1.0).
  void setIntensity(double intensity) {
    setConfiguration(_config.copyWith(
      intensity: intensity,
      preset: SubBassPreset.custom,
    ));
  }

  /// Sets cutoff frequency in Hz (30.0 to 120.0).
  void setFrequency(double frequencyHz) {
    setConfiguration(_config.copyWith(
      frequencyHz: frequencyHz,
      preset: SubBassPreset.custom,
    ));
  }

  /// Sets added sub-bass output level in dB (-12.0 to +6.0).
  void setOutputLevel(double outputLevelDb) {
    setConfiguration(_config.copyWith(
      outputLevelDb: outputLevelDb,
      preset: SubBassPreset.custom,
    ));
  }

  /// Applies a named preset.
  void applyPreset(SubBassPreset preset) {
    setConfiguration(SubBassConfiguration.fromPreset(preset, enabled: _config.enabled));
  }

  /// Resets Sub-Bass Enhancement parameters to factory defaults.
  void resetToDefaults() {
    setConfiguration(const SubBassConfiguration(
      enabled: false,
      intensity: 0.50,
      frequencyHz: 60.0,
      outputLevelDb: 0.0,
      preset: SubBassPreset.natural,
    ));
  }
}
