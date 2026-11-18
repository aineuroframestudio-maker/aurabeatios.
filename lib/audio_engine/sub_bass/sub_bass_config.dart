// Copyright (C) 2026 AuraBeat Project.
// Sub-Bass Enhancement Engine Configuration & Preset Architecture.

enum SubBassPreset {
  natural('Natural Sub-Bass', 50.0, 0.40, 0.0, 'Subtle warmth, organic low-end extension preserving natural acoustic balance.'),
  deep('Deep Sub-Bass', 40.0, 0.70, 2.0, 'Ultra-low rumble with 35–45 Hz focus for cinematic subwoofers.'),
  balanced('Balanced Bass', 65.0, 0.55, 1.0, 'Well-rounded low-frequency body suitable for all modern genres.'),
  powerful('Powerful Bass', 80.0, 0.85, 3.0, 'High-energy electronic and hip-hop punch with heavy low-end impact.'),
  studio('Studio Sub-Bass', 40.0, 0.35, -1.0, 'Reference linear response tuned for precision studio monitors and IEMs.'),
  custom('Custom', 60.0, 0.50, 0.0, 'User-defined parameters.');

  final String displayName;
  final double defaultFrequencyHz;
  final double defaultIntensity;
  final double defaultOutputLevelDb;
  final String description;

  const SubBassPreset(
    this.displayName,
    this.defaultFrequencyHz,
    this.defaultIntensity,
    this.defaultOutputLevelDb,
    this.description,
  );

  static SubBassPreset fromName(String name) {
    for (final p in SubBassPreset.values) {
      if (p.displayName.toLowerCase() == name.toLowerCase() || p.name.toLowerCase() == name.toLowerCase()) {
        return p;
      }
    }
    return SubBassPreset.custom;
  }
}

/// Immutable configuration holding current Sub-Bass Enhancement parameters.
class SubBassConfiguration {
  final bool enabled;
  final double intensity; // 0.0 (0%) to 1.0 (100%)
  final double frequencyHz; // 30.0 Hz to 120.0 Hz
  final double outputLevelDb; // -12.0 dB to +6.0 dB
  final SubBassPreset preset;

  const SubBassConfiguration({
    this.enabled = false,
    this.intensity = 0.50,
    this.frequencyHz = 60.0,
    this.outputLevelDb = 0.0,
    this.preset = SubBassPreset.natural,
  });

  SubBassConfiguration copyWith({
    bool? enabled,
    double? intensity,
    double? frequencyHz,
    double? outputLevelDb,
    SubBassPreset? preset,
  }) {
    return SubBassConfiguration(
      enabled: enabled ?? this.enabled,
      intensity: (intensity ?? this.intensity).clamp(0.0, 1.0),
      frequencyHz: (frequencyHz ?? this.frequencyHz).clamp(30.0, 120.0),
      outputLevelDb: (outputLevelDb ?? this.outputLevelDb).clamp(-12.0, 6.0),
      preset: preset ?? this.preset,
    );
  }

  /// Creates a configuration applying preset default values.
  static SubBassConfiguration fromPreset(SubBassPreset preset, {bool enabled = true}) {
    return SubBassConfiguration(
      enabled: enabled,
      intensity: preset.defaultIntensity,
      frequencyHz: preset.defaultFrequencyHz,
      outputLevelDb: preset.defaultOutputLevelDb,
      preset: preset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'intensity': intensity,
      'frequencyHz': frequencyHz,
      'outputLevelDb': outputLevelDb,
      'preset': preset.displayName,
    };
  }

  factory SubBassConfiguration.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const SubBassConfiguration();
    return SubBassConfiguration(
      enabled: map['enabled'] is bool ? map['enabled'] as bool : false,
      intensity: (map['intensity'] is num ? (map['intensity'] as num).toDouble() : 0.50).clamp(0.0, 1.0),
      frequencyHz: (map['frequencyHz'] is num ? (map['frequencyHz'] as num).toDouble() : 60.0).clamp(30.0, 120.0),
      outputLevelDb: (map['outputLevelDb'] is num ? (map['outputLevelDb'] as num).toDouble() : 0.0).clamp(-12.0, 6.0),
      preset: map['preset'] is String ? SubBassPreset.fromName(map['preset'] as String) : SubBassPreset.natural,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubBassConfiguration &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          intensity == other.intensity &&
          frequencyHz == other.frequencyHz &&
          outputLevelDb == other.outputLevelDb &&
          preset == other.preset;

  @override
  int get hashCode => Object.hash(enabled, intensity, frequencyHz, outputLevelDb, preset);
}
