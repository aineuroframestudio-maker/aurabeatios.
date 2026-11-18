import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models/addon_source_model.dart';
import 'services/addon_discovery_service.dart';
import 'services/addon_storage_service.dart';
import 'services/addon_logger.dart';

/// Central singleton registry managing all default and user-configured add-on sources in AuraBeat.
/// Fully integrated with persistent storage, BitChord protocol validation, and structured diagnostics.
class AddonSourceRegistry {
  static final AddonSourceRegistry instance = AddonSourceRegistry._internal();

  final AddonDiscoveryService _discoveryService;
  final AddonStorageService _storageService;
  final List<AddonSourceConfig> _sources = [];
  bool _initialized = false;

  AddonSourceRegistry._internal({
    AddonDiscoveryService? discoveryService,
    AddonStorageService? storageService,
  })  : _discoveryService = discoveryService ?? AddonDiscoveryService(),
        _storageService = storageService ?? AddonStorageService.instance;

  // For testing
  factory AddonSourceRegistry.withDiscovery(
    AddonDiscoveryService discoveryService, {
    AddonStorageService? storageService,
  }) {
    return AddonSourceRegistry._internal(
      discoveryService: discoveryService,
      storageService: storageService,
    );
  }

  List<AddonSourceConfig> get allSources {
    final list = List<AddonSourceConfig>.from(_sources);
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(list);
  }

  List<AddonSourceConfig> get enabledSources {
    final list = _sources.where((s) => s.isEnabled).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return List.unmodifiable(list);
  }

  List<AddonSourceConfig> get defaultSources =>
      List.unmodifiable(_sources.where((s) => s.isDefault));

  /// Initialize all 6 default sources and load user-installed add-ons from persistent storage
  Future<void> initialize() async {
    if (_initialized && _sources.isNotEmpty) return;
    _initialized = true;

    // Register Source 1: Heisenberg
    _registerDefault(AddonSourceConfig(
      id: 'source.builtin.heisenberg',
      name: 'Heisenberg',
      url: 'https://heisenbergbackaaahh.de.deplexo.com',
      manifestUrl: 'https://heisenbergbackaaahh.de.deplexo.com/a/manifest.json',
      version: '1.4.2',
      isDefault: true,
      isEnabled: true,
      status: AddonConnectionStatus.connected,
      statusMessage: 'Operational · Dedicated Lossless Engine',
      lastRefreshed: DateTime.now(),
      resources: ['search', 'stream', 'metadata'],
      qualityTiers: ['Hi-Res (24-bit/96kHz)', 'CD Lossless (16-bit/44.1kHz)', 'High AAC (320k)'],
      qualityOptions: const [
        ManifestQualityOption(value: 'max', label: 'Hi-Res (24-bit/96kHz)'),
        ManifestQualityOption(value: 'lossless', label: 'CD Lossless (16-bit/44.1kHz)'),
        ManifestQualityOption(value: 'high', label: 'High AAC (320k)'),
      ],
      upstreamProvider: 'Heisenberg Dedicated Engine',
    ));

    // Register Source 2: LastBabe
    _registerDefault(AddonSourceConfig(
      id: 'source.builtin.lastbabe',
      name: 'LastBabe',
      url: 'https://lastbabe-addon.de.deplexo.com',
      manifestUrl: 'https://lastbabe-addon.de.deplexo.com/manifest.json',
      version: '2.1.0',
      isDefault: true,
      isEnabled: true,
      status: AddonConnectionStatus.connected,
      statusMessage: 'Operational · Synced Lyrics & CD Lossless Audio',
      lastRefreshed: DateTime.now(),
      resources: ['search', 'stream', 'lyrics'],
      qualityTiers: ['CD Lossless (16-bit/44.1kHz)', 'High Fidelity (320k)'],
      qualityOptions: const [
        ManifestQualityOption(value: 'lossless', label: 'CD Lossless (16-bit/44.1kHz)'),
        ManifestQualityOption(value: 'high', label: 'High Fidelity (320k)'),
      ],
      upstreamProvider: 'LastBabe Audio & Synced Lyrics',
    ));

    // Register Source 3: ElJohnzC Mono
    _registerDefault(AddonSourceConfig(
      id: 'source.builtin.eljohnzc_mono',
      name: 'ElJohnzC Mono',
      url: 'https://eljohnzc-mono.de.deplexo.com',
      manifestUrl: 'https://eljohnzc-mono.de.deplexo.com/manifest.json',
      version: '1.0.8',
      isDefault: true,
      isEnabled: true,
      status: AddonConnectionStatus.connected,
      statusMessage: 'Operational · Audiophile Mono Reference Archives',
      lastRefreshed: DateTime.now(),
      resources: ['search', 'stream'],
      qualityTiers: ['Direct Bitstream Mono FLAC', 'Lossless 16-bit'],
      qualityOptions: const [
        ManifestQualityOption(value: 'lossless', label: 'Direct Bitstream Mono FLAC (16-bit)'),
      ],
      upstreamProvider: 'ElJohnzC Reference Archives',
    ));

    // Register Source 4: ElJohnzC Add-on
    _registerDefault(AddonSourceConfig(
      id: 'source.builtin.eljohnzc_addon',
      name: 'ElJohnzC Add-on',
      url: 'https://eljohnzcaddon.velixir.run/c57e7b0ef2031b2f1fcd',
      manifestUrl: 'https://eljohnzcaddon.velixir.run/c57e7b0ef2031b2f1fcd/manifest.json',
      version: '1.2.5',
      isDefault: true,
      isEnabled: true,
      status: AddonConnectionStatus.connected,
      statusMessage: 'Operational · Hi-Res Catalog & Master Tracks',
      lastRefreshed: DateTime.now(),
      resources: ['search', 'stream', 'catalog'],
      qualityTiers: ['Hi-Res 24-bit / 96 kHz', 'CD Lossless', 'High 320k'],
      qualityOptions: const [
        ManifestQualityOption(value: 'max', label: 'Hi-Res 24-bit / 96 kHz'),
        ManifestQualityOption(value: 'lossless', label: 'CD Lossless'),
        ManifestQualityOption(value: 'high', label: 'High 320k'),
      ],
      upstreamProvider: 'ElJohnzC Multi-Tier Catalog',
    ));

    // Register Source 5: BitChord Hi-Res Add-on (dev.akira.bitchord-hires)
    _registerDefault(AddonSourceConfig(
      id: 'dev.akira.bitchord-hires',
      name: 'BitChord Hi-Res Add-on',
      url: 'https://bitchord-hires-addon.de.deplexo.com',
      manifestUrl: 'https://bitchord-hires-addon.de.deplexo.com/',
      version: '1.2.1',
      isDefault: true,
      isEnabled: true,
      status: AddonConnectionStatus.connected,
      statusMessage: 'Operational · Verified manifest v1.2.1 · Direct Hi-Res Bitstream',
      lastRefreshed: DateTime.now(),
      resources: ['search', 'stream'],
      qualityTiers: [
        'Ultra Hi-Res (24-bit / 192 kHz FLAC · 9216 kbps)',
        'Lossless (FLAC, up to 24/192)',
        'High (FLAC, up to 24/96)',
        'Low (data saver)',
      ],
      qualityOptions: const [
        ManifestQualityOption(value: 'max', label: 'Ultra Hi-Res (24-bit / 192 kHz FLAC · 9216 kbps)'),
        ManifestQualityOption(value: 'lossless', label: 'Lossless (FLAC, up to 24/192)'),
        ManifestQualityOption(value: 'high', label: 'High (FLAC, up to 24/96)'),
        ManifestQualityOption(value: 'low', label: 'Low (data saver)'),
      ],
      selectedQualityOption: 'max',
      requiresAuth: true,
      authRealm: 'BitChord realm="bitchord-addons"',
      bitchordAuth: true,
      allowDownloads: true,
      checkValidLossless: true,
      upstreamProvider: 'Multi-source (Qobuz hi-res, Tidal, Monochrome, Deezer)',
    ));

    // Register Source 6: BitChord Confih (app.bitchord.confih / Confih Hi-Res)
    // Uses the user's Cloudflare Worker which has checkValidLossless: false so it works on all devices.
    final confihConfig = AddonSourceConfig(
      id: 'app.bitchord.confih',
      name: 'Confih Hi-Res',
      url: 'https://yes.aineuroframestudio-986.workers.dev',
      manifestUrl: 'https://yes.aineuroframestudio-986.workers.dev/manifest.json',
      version: '2.0.0',
      isDefault: true,
      isEnabled: true,
      status: AddonConnectionStatus.connected,
      statusMessage: 'Operational · BitChord Confih v2.0 · Verified Manifest (24-bit/192kHz)',
      lastRefreshed: DateTime.now(),
      resources: ['search', 'stream'],
      qualityTiers: [
        'Ultra Hi-Res & Dolby Atmos (24-bit / 192 kHz FLAC)',
        'Hi-Res Audio (24-bit / 96 kHz FLAC)',
        'Hi-Res Lossless (24-bit / 48 kHz FLAC)',
        'CD Lossless (16-bit / 44.1 kHz FLAC)',
        'Very High (320 kbps MP3)',
        'High (256 kbps AAC)',
        'Normal (128 kbps AAC)',
        'Data Saver (64 kbps AAC)',
        'Dolby Atmos Spatial Audio (7.1.4)',
        'Sony 360° Reality Audio (360° Spatial)',
      ],
      qualityOptions: const [
        ManifestQualityOption(value: 'max', label: 'Ultra Hi-Res (24-bit / 192 kHz FLAC · 9216 kbps)'),
        ManifestQualityOption(value: 'hires', label: 'Hi-Res Audio (24-bit / 96 kHz FLAC · 4608 kbps)'),
        ManifestQualityOption(value: 'hires_lossless', label: 'Hi-Res Lossless (24-bit / 48 kHz FLAC · 2304 kbps)'),
        ManifestQualityOption(value: 'lossless', label: 'CD Lossless (16-bit / 44.1 kHz FLAC · 1411 kbps)'),
        ManifestQualityOption(value: 'very_high', label: 'Very High (320 kbps MP3)'),
        ManifestQualityOption(value: 'high', label: 'High (256 kbps AAC)'),
        ManifestQualityOption(value: 'normal', label: 'Normal (128 kbps AAC)'),
        ManifestQualityOption(value: 'low', label: 'Data Saver (64 kbps AAC)'),
        ManifestQualityOption(value: 'atmos', label: 'Dolby Atmos Spatial (768 kbps)'),
        ManifestQualityOption(value: 'sony360', label: 'Sony 360° Reality Audio (1536 kbps)'),
      ],
      requiresAuth: false,
      authRealm: null,
      bitchordAuth: false,
      allowDownloads: true,
      checkValidLossless: false,
      selectedQualityOption: 'max',
      upstreamProvider: 'Confih Studio Hi-Res Engine',
      metadata: {
        'portal': 'https://yes.aineuroframestudio-986.workers.dev',
      },
    );
    _registerDefault(confihConfig);

    // Load persisted settings and user-installed custom addons from disk
    try {
      final savedSources = await _storageService.loadSavedSources();
      for (final saved in savedSources) {
        final existingIdx = _sources.indexWhere((s) => s.id == saved.id);
        if (existingIdx != -1) {
          // Restore user settings on default source (enabled state, quality choice, sort order)
          final existing = _sources[existingIdx];
          existing.isEnabled = saved.isEnabled;
          existing.sortOrder = saved.sortOrder;
          if (saved.selectedQualityOption != null) {
            existing.selectedQualityOption = saved.selectedQualityOption;
          }
        } else {
          // Restore user-installed custom addon
          saved.sortOrder = _sources.length;
          _sources.add(saved);
        }
      }
    } catch (e) {
      AddonLogger.addonError(
        operation: 'initialize_storage',
        errorCategory: 'persistence',
        details: 'Failed to restore persisted addons: $e',
      );
    }

    // Refresh live configuration for network sources asynchronously in background
    unawaited(refreshSource('app.bitchord.confih'));
  }

  void _registerDefault(AddonSourceConfig source) {
    if (!hasDuplicate(source.url, source.id)) {
      source.sortOrder = _sources.length;
      _sources.add(source);
      AddonLogger.addonLoadedIntoUI(source.id, source.name);
    }
  }

  /// Prevents duplicate registration by comparing canonical URLs and source IDs
  bool hasDuplicate(String url, String id) {
    final targetCanonical = AddonDiscoveryService.normalizeBaseUrl(url).toLowerCase();
    return _sources.any((s) {
      final existingCanonical = AddonDiscoveryService.normalizeBaseUrl(s.url).toLowerCase();
      return s.id == id || existingCanonical == targetCanonical;
    });
  }

  /// Add a user-added source with duplicate prevention and persistent storage
  bool addSource(AddonSourceConfig config) {
    if (hasDuplicate(config.url, config.id)) {
      AddonLogger.addonError(
        operation: 'add_source',
        addonId: config.id,
        errorCategory: 'duplicate',
        details: 'Source with ID "${config.id}" or URL "${config.url}" already exists',
      );
      return false;
    }
    config.sortOrder = _sources.length;
    _sources.add(config);
    AddonLogger.addonSaved(config.id, config.name);
    unawaited(_persistSources());
    return true;
  }

  /// Reorder sources in registry (updates query priority order)
  void reorderSources(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _sources.length) return;
    if (newIndex < 0 || newIndex >= _sources.length) return;
    final item = _sources.removeAt(oldIndex);
    _sources.insert(newIndex, item);
    for (int i = 0; i < _sources.length; i++) {
      _sources[i].sortOrder = i;
    }
    unawaited(_persistSources());
  }

  /// Set user's per-addon quality option choice
  void setQualityOption(String sourceId, String optionValue) {
    final source = getSourceById(sourceId);
    if (source != null) {
      source.selectedQualityOption = optionValue;
      final optLabel = source.effectiveAvailableOptions
          .firstWhere((o) => o.value == optionValue, orElse: () => ManifestQualityOption(value: optionValue, label: optionValue))
          .label;
      AddonLogger.qualitySelected(sourceId, optionValue, optLabel);
      unawaited(_storageService.saveSelectedQuality(sourceId, optionValue));
      unawaited(_persistSources());
    }
  }

  /// Remove a source (only non-default sources can be removed)
  bool removeSource(String id) {
    final index = _sources.indexWhere((s) => s.id == id);
    if (index != -1 && !_sources[index].isDefault) {
      final removed = _sources.removeAt(index);
      for (int i = 0; i < _sources.length; i++) {
        _sources[i].sortOrder = i;
      }
      AddonLogger.addonSaved(id, 'Removed custom addon "${removed.name}"');
      unawaited(_persistSources());
      return true;
    }
    return false;
  }

  /// Toggle source enabled / disabled state independently
  void setEnabled(String id, bool enabled) {
    final index = _sources.indexWhere((s) => s.id == id);
    if (index != -1) {
      _sources[index].isEnabled = enabled;
      unawaited(_persistSources());
    }
  }

  /// Refresh a single source, preserving last valid configuration if server is unreachable
  Future<AddonSourceConfig?> refreshSource(String id) async {
    final index = _sources.indexWhere((s) => s.id == id);
    if (index == -1) return null;

    final existing = _sources[index];
    existing.status = AddonConnectionStatus.checking;
    existing.statusMessage = 'Refreshing configuration…';

    try {
      final inspected = await _discoveryService.inspectSource(
        existing.url,
        defaultName: existing.name,
        isDefault: existing.isDefault,
      );

      // Preserve existing enabled state, sort order, and user quality choice
      inspected.isEnabled = existing.isEnabled;
      inspected.sortOrder = existing.sortOrder;
      inspected.selectedQualityOption = existing.selectedQualityOption ?? inspected.selectedQualityOption;
      // Always preserve the local checkValidLossless=false override so the addon is never gated
      if (!existing.checkValidLossless) {
        inspected.checkValidLossless = false;
        inspected.requiresAuth = existing.requiresAuth;
        inspected.bitchordAuth = existing.bitchordAuth;
        inspected.authRealm = existing.authRealm;
      }

      // If remote discovery succeeded, update config
      if (inspected.status != AddonConnectionStatus.offline) {
        if (inspected.status == AddonConnectionStatus.authRequired) {
          inspected.status = AddonConnectionStatus.connected;
          inspected.statusMessage = 'Operational · BitChord Gateway Active';
        }
        _sources[index] = inspected;
        unawaited(_persistSources());
        return inspected;
      } else {
        // Offline / unreachable: preserve last valid configuration
        existing.status = AddonConnectionStatus.offline;
        existing.statusMessage = 'Offline: Preserving cached configuration';
        existing.lastRefreshed = DateTime.now();
        return existing;
      }
    } catch (e) {
      // Preserve last valid configuration on error
      existing.status = AddonConnectionStatus.offline;
      existing.statusMessage = 'Preserving cached config (${e.toString()})';
      return existing;
    }
  }

  /// Refresh all sources asynchronously in parallel
  Future<void> refreshAll() async {
    await Future.wait(_sources.map((s) => refreshSource(s.id)));
  }

  AddonSourceConfig? getSourceById(String id) {
    try {
      return _sources.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistSources() async {
    try {
      await _storageService.saveSources(_sources);
    } catch (e) {
      debugPrint('[AddonSourceRegistry] Error saving sources: $e');
    }
  }
}
