// AuraBeat Add-on Source Models
// Defines wire shapes, metadata, capabilities, quality tiers, and status for add-on sources.

enum AddonConnectionStatus {
  connected,
  authRequired,
  degraded,
  unreachable,
  offline,
  checking,
}

class AddonQualityTier {
  final String key;
  final String label;
  final String description;

  const AddonQualityTier({
    required this.key,
    required this.label,
    required this.description,
  });

  static const max = AddonQualityTier(
    key: 'max',
    label: 'Hi-Res & Dolby Atmos',
    description: '24-bit / 192–384 kHz FLAC / E-AC-3',
  );

  static const lossless = AddonQualityTier(
    key: 'lossless',
    label: 'CD Lossless',
    description: '16-bit / 44.1 kHz FLAC',
  );

  static const high = AddonQualityTier(
    key: 'high',
    label: 'High Fidelity',
    description: '320 kbps AAC / MP3',
  );

  static const low = AddonQualityTier(
    key: 'low',
    label: 'Data Saver',
    description: '96–128 kbps AAC',
  );
}

/// BitChord manifest setting option for audio quality dropdowns
class ManifestQualityOption {
  final String value;
  final String label;

  const ManifestQualityOption({
    required this.value,
    required this.label,
  });

  Map<String, dynamic> toJson() => {
    'value': value,
    'label': label,
  };

  factory ManifestQualityOption.fromJson(Map<String, dynamic> json) {
    return ManifestQualityOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? json['value']?.toString() ?? '',
    );
  }

  factory ManifestQualityOption.fromMap(Map map) {
    return ManifestQualityOption(
      value: map['value']?.toString() ?? '',
      label: map['label']?.toString() ?? map['value']?.toString() ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ManifestQualityOption &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$label ($value)';
}

class AddonSourceConfig {
  final String id;
  final String name;
  final String url;
  final String manifestUrl;
  final String version;
  final bool isDefault;
  bool isEnabled;
  AddonConnectionStatus status;
  String statusMessage;
  DateTime? lastRefreshed;
  DateTime? lastSuccess;
  String? lastError;
  int sortOrder;
  final List<String> resources;
  final List<String> qualityTiers;
  final List<ManifestQualityOption> qualityOptions;
  String? selectedQualityOption;
  bool requiresAuth;
  String? authRealm;
  bool bitchordAuth;
  bool allowDownloads;
  bool checkValidLossless;
  final String? upstreamProvider;
  final Map<String, dynamic> rawSettings;
  final Map<String, dynamic> metadata;

  AddonSourceConfig({
    required this.id,
    required this.name,
    required this.url,
    required this.manifestUrl,
    required this.version,
    this.isDefault = false,
    this.isEnabled = true,
    this.status = AddonConnectionStatus.connected,
    this.statusMessage = 'Operational',
    this.lastRefreshed,
    this.lastSuccess,
    this.lastError,
    this.sortOrder = 0,
    this.resources = const ['search', 'stream'],
    this.qualityTiers = const ['Hi-Res (24-bit)', 'Lossless (16-bit)', 'High (320k)'],
    this.qualityOptions = const [],
    this.selectedQualityOption,
    this.requiresAuth = false,
    this.authRealm,
    this.bitchordAuth = false,
    this.allowDownloads = true,
    this.checkValidLossless = false,
    this.upstreamProvider,
    this.rawSettings = const {},
    this.metadata = const {},
  });

  /// True if the manifest specifically declares key: "quality" settings options
  bool get hasManifestQualityOptions => qualityOptions.isNotEmpty;

  /// Returns the declared options, or BitChord native fallback tiers (LOSSLESS, HIGH, LOW) if unconfigured
  List<ManifestQualityOption> get effectiveAvailableOptions {
    if (qualityOptions.isNotEmpty) {
      return qualityOptions;
    }
    // BitChord standard native tiers when manifest specifies no quality options
    return const [
      ManifestQualityOption(value: 'lossless', label: 'LOSSLESS (Bit-exact FLAC/ALAC · 1411 kbps)'),
      ManifestQualityOption(value: 'high', label: 'HIGH (Best lossy ~320 kbps)'),
      ManifestQualityOption(value: 'low', label: 'LOW (Data saver <=128 kbps)'),
    ];
  }

  /// Best quality option declared in manifest (BitChord Rule 1: best option first)
  String get effectiveQualityOption {
    if (selectedQualityOption != null && selectedQualityOption!.isNotEmpty) {
      return selectedQualityOption!;
    }
    if (qualityOptions.isNotEmpty) {
      return qualityOptions.first.value;
    }
    return 'max';
  }

  /// Readable label of the currently active quality option
  String get activeQualityLabel {
    final curVal = effectiveQualityOption;
    for (final opt in effectiveAvailableOptions) {
      if (opt.value == curVal) return opt.label;
    }
    return curVal.toUpperCase();
  }

  AddonSourceConfig copyWith({
    String? id,
    String? name,
    String? url,
    String? manifestUrl,
    String? version,
    bool? isDefault,
    bool? isEnabled,
    AddonConnectionStatus? status,
    String? statusMessage,
    DateTime? lastRefreshed,
    DateTime? lastSuccess,
    String? lastError,
    int? sortOrder,
    List<String>? resources,
    List<String>? qualityTiers,
    List<ManifestQualityOption>? qualityOptions,
    String? selectedQualityOption,
    bool? requiresAuth,
    String? authRealm,
    bool? bitchordAuth,
    bool? allowDownloads,
    bool? checkValidLossless,
    String? upstreamProvider,
    Map<String, dynamic>? rawSettings,
    Map<String, dynamic>? metadata,
  }) {
    return AddonSourceConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      manifestUrl: manifestUrl ?? this.manifestUrl,
      version: version ?? this.version,
      isDefault: isDefault ?? this.isDefault,
      isEnabled: isEnabled ?? this.isEnabled,
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      lastRefreshed: lastRefreshed ?? this.lastRefreshed,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      lastError: lastError ?? this.lastError,
      sortOrder: sortOrder ?? this.sortOrder,
      resources: resources ?? this.resources,
      qualityTiers: qualityTiers ?? this.qualityTiers,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      selectedQualityOption: selectedQualityOption ?? this.selectedQualityOption,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      authRealm: authRealm ?? this.authRealm,
      bitchordAuth: bitchordAuth ?? this.bitchordAuth,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      checkValidLossless: checkValidLossless ?? this.checkValidLossless,
      upstreamProvider: upstreamProvider ?? this.upstreamProvider,
      rawSettings: rawSettings ?? this.rawSettings,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'manifestUrl': manifestUrl,
    'version': version,
    'isDefault': isDefault,
    'isEnabled': isEnabled,
    'status': status.name,
    'statusMessage': statusMessage,
    'lastRefreshed': lastRefreshed?.toIso8601String(),
    'lastSuccess': lastSuccess?.toIso8601String(),
    'lastError': lastError,
    'sortOrder': sortOrder,
    'resources': resources,
    'qualityTiers': qualityTiers,
    'qualityOptions': qualityOptions.map((o) => o.toJson()).toList(),
    'selectedQualityOption': selectedQualityOption,
    'requiresAuth': requiresAuth,
    'authRealm': authRealm,
    'bitchordAuth': bitchordAuth,
    'allowDownloads': allowDownloads,
    'checkValidLossless': checkValidLossless,
    'upstreamProvider': upstreamProvider,
    'rawSettings': rawSettings,
    'metadata': metadata,
  };

  factory AddonSourceConfig.fromJson(Map<String, dynamic> json) {
    return AddonSourceConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      manifestUrl: json['manifestUrl'] as String? ?? json['url'] as String,
      version: json['version'] as String? ?? '1.0.0',
      isDefault: json['isDefault'] as bool? ?? false,
      isEnabled: json['isEnabled'] as bool? ?? true,
      status: AddonConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AddonConnectionStatus.connected,
      ),
      statusMessage: json['statusMessage'] as String? ?? 'Operational',
      lastRefreshed: json['lastRefreshed'] != null
          ? DateTime.tryParse(json['lastRefreshed'] as String)
          : null,
      lastSuccess: json['lastSuccess'] != null
          ? DateTime.tryParse(json['lastSuccess'] as String)
          : null,
      lastError: json['lastError'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      resources: (json['resources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['search', 'stream'],
      qualityTiers: (json['qualityTiers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          ['Hi-Res (24-bit)', 'Lossless (16-bit)'],
      qualityOptions: (json['qualityOptions'] as List<dynamic>?)
              ?.map((o) {
                if (o is Map) {
                  return ManifestQualityOption.fromMap(o);
                }
                return ManifestQualityOption(value: o.toString(), label: o.toString());
              })
              .where((opt) => opt.value.isNotEmpty)
              .toList() ??
          const [],
      selectedQualityOption: json['selectedQualityOption'] as String?,
      requiresAuth: json['requiresAuth'] as bool? ?? false,
      authRealm: json['authRealm'] as String?,
      bitchordAuth: json['bitchordAuth'] as bool? ?? false,
      allowDownloads: json['allowDownloads'] is bool
          ? json['allowDownloads'] as bool
          : (json['allowDownloads'] == 1 || json['allowDownloads'] == null),
      checkValidLossless: json['checkValidLossless'] is bool
          ? json['checkValidLossless'] as bool
          : json['checkValidLossless'] == 1,
      upstreamProvider: json['upstreamProvider'] as String?,
      rawSettings: json['rawSettings'] is Map
          ? Map<String, dynamic>.from(json['rawSettings'] as Map)
          : {},
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : {},
    );
  }
}
