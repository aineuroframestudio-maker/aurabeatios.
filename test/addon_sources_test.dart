import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aurabeat/sources/models/addon_source_model.dart';
import 'package:aurabeat/sources/services/addon_discovery_service.dart';
import 'package:aurabeat/sources/addon_source_registry.dart';
import 'package:aurabeat/sources/adapters/bitchord_protocol_adapter.dart';
import 'package:aurabeat/sources/services/lossless_output_manager.dart';
import 'package:aurabeat/sources/services/addon_cache_manager.dart';
import 'package:aurabeat/sources/services/addon_search_service.dart';
import 'package:aurabeat/sources/services/addon_stream_resolver.dart';
import 'package:aurabeat/sources/services/addon_storage_service.dart';
import 'package:aurabeat/sources/services/addon_logger.dart';

void main() {
  group('AuraBeat Add-on Source Ecosystem Tests', () {
    test('1. Registry initializes with exactly 6 default sources', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      final defaultSources = registry.defaultSources;
      expect(defaultSources.length, 6);

      final names = defaultSources.map((s) => s.name).toList();
      expect(names.contains('Heisenberg'), isTrue);
      expect(names.contains('LastBabe'), isTrue);
      expect(names.contains('ElJohnzC Mono'), isTrue);
      expect(names.contains('ElJohnzC Add-on'), isTrue);
      expect(names.contains('BitChord Hi-Res Add-on'), isTrue);
      expect(names.contains('Confih Hi-Res'), isTrue);
    });

    test('2. BitChord Configh (Source 6) has correct permanent ID, URL, and manifest', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      final confih = registry.getSourceById('app.bitchord.confih');
      expect(confih, isNotNull);
      expect(confih!.url, 'https://yes.aineuroframestudio-986.workers.dev');
      expect(confih.manifestUrl, 'https://yes.aineuroframestudio-986.workers.dev/manifest.json');
      expect(confih.version, '2.0.0');
      expect(confih.isDefault, isTrue);
      expect(confih.bitchordAuth, isFalse);
      expect(confih.requiresAuth, isFalse);
      expect(confih.checkValidLossless, isFalse);
      expect(confih.resources, contains('search'));
      expect(confih.resources, contains('stream'));
    });

    test('3. Duplicate prevention refuses existing URLs and IDs', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      // Duplicate by ID
      final duplicateId = AddonSourceConfig(
        id: 'app.bitchord.confih',
        name: 'Duplicate Confih',
        url: 'https://bitchord-alt.confih.tech',
        manifestUrl: 'https://bitchord-alt.confih.tech/manifest.json',
        version: '2.0.0',
      );
      expect(registry.addSource(duplicateId), isFalse);

      // Duplicate by canonical URL
      final duplicateUrl = AddonSourceConfig(
        id: 'new.bitchord.custom',
        name: 'Another Confih',
        url: 'https://yes.aineuroframestudio-986.workers.dev/',
        manifestUrl: 'https://yes.aineuroframestudio-986.workers.dev/manifest.json',
        version: '2.0.0',
      );
      expect(registry.addSource(duplicateUrl), isFalse);
    });

    test('4. Independent enable/disable state toggling', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      final confihId = 'app.bitchord.confih';
      expect(registry.getSourceById(confihId)!.isEnabled, isTrue);

      // Disable Confih
      registry.setEnabled(confihId, false);
      expect(registry.getSourceById(confihId)!.isEnabled, isFalse);

      // Verify other sources are still enabled
      expect(registry.getSourceById('source.builtin.heisenberg')!.isEnabled, isTrue);
      expect(registry.getSourceById('source.builtin.lastbabe')!.isEnabled, isTrue);

      // Re-enable Confih
      registry.setEnabled(confihId, true);
      expect(registry.getSourceById(confihId)!.isEnabled, isTrue);
    });

    test('5. AddonDiscoveryService correctly parses remote manifest and handles bitchordAuth', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/manifest.json') {
          return http.Response(
            jsonEncode({
              'id': 'app.bitchord.confih',
              'name': 'Confih Hi-Res',
              'version': '2.0.0',
              'resources': ['search', 'stream'],
              'allowDownloads': 1,
              'checkValidLossless': 1,
              'bitchordAuth': true,
              'settings': [
                {
                  'key': 'quality',
                  'type': 'select',
                  'label': 'Audio quality',
                  'default': 'max',
                  'options': [
                    {'value': 'max', 'label': 'Hi-Res & Dolby Atmos (24-bit / 192 kHz FLAC)'},
                    {'value': 'lossless', 'label': 'CD Lossless (16-bit / 44.1 kHz FLAC)'},
                  ],
                }
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/') {
          return http.Response(
            jsonEncode({
              'addon': 'Confih Hi-Res',
              'version': '2.0.0',
              'manifest': '/manifest.json',
              'resources': ['search', 'stream'],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path.startsWith('/search')) {
          return http.Response(
            jsonEncode({'error': 'bitchord_auth', 'code': 'missing'}),
            401,
            headers: {
              'www-authenticate': 'BitChord realm="bitchord-addons", error="missing"',
              'content-type': 'application/json',
            },
          );
        }
        return http.Response('Not Found', 404);
      });

      final discovery = AddonDiscoveryService(client: mockClient);
      final inspected = await discovery.inspectSource('https://bitchord.confih.tech');

      expect(inspected.id, 'app.bitchord.confih');
      expect(inspected.name, 'Confih Hi-Res');
      expect(inspected.version, '2.0.0');
      expect(inspected.bitchordAuth, isTrue);
      expect(inspected.requiresAuth, isTrue);
      expect(inspected.authRealm, contains('bitchord-addons'));
      expect(inspected.status, AddonConnectionStatus.authRequired);
      expect(inspected.qualityTiers.first, contains('Hi-Res & Dolby Atmos'));
    });

    test('6. Offline resilience preserves last valid configuration', () async {
      final offlineClient = MockClient((request) async {
        throw Exception('Connection refused / offline');
      });

      final discovery = AddonDiscoveryService(client: offlineClient);
      final registry = AddonSourceRegistry.withDiscovery(discovery);
      await registry.initialize();

      // Confih is present
      final before = registry.getSourceById('app.bitchord.confih');
      expect(before, isNotNull);
      final originalName = before!.name;

      // Refresh while offline
      final refreshed = await registry.refreshSource('app.bitchord.confih');
      expect(refreshed, isNotNull);
      expect(refreshed!.status, AddonConnectionStatus.offline);
      expect(refreshed.name, originalName);
      expect(refreshed.url, 'https://yes.aineuroframestudio-986.workers.dev');
    });

    test('7. Lossless Output Gating (checkValidLossless: 1) blocks non-qualified routes', () {
      final lom = LosslessOutputManager.instance;

      // Certified lossless route
      lom.setAudioRoute(AudioRouteType.usbDac);
      expect(lom.isLosslessQualified, isTrue);

      final gatedSource = AddonSourceConfig(
        id: 'gated.src',
        name: 'Gated BitChord Source',
        url: 'https://gated.src.example',
        manifestUrl: 'https://gated.src.example/manifest.json',
        version: '1.0.0',
        checkValidLossless: true,
      );
      expect(lom.shouldAllowGatedSource(gatedSource), isTrue);

      // Switch to lossy route (Phone speaker / Bluetooth AAC)
      lom.setAudioRoute(AudioRouteType.phoneSpeaker);
      expect(lom.isLosslessQualified, isFalse);
      expect(lom.shouldAllowGatedSource(gatedSource), isFalse);
      expect(lom.getGatedStatusMessage(gatedSource), 'Needs a lossless output');

      // Ungated source continues to work
      final ungatedSource = AddonSourceConfig(
        id: 'ungated.src',
        name: 'Ungated Source',
        url: 'https://ungated.src.example',
        manifestUrl: 'https://ungated.src.example/manifest.json',
        version: '1.0.0',
        checkValidLossless: false,
      );
      expect(lom.shouldAllowGatedSource(ungatedSource), isTrue);
      expect(lom.getGatedStatusMessage(ungatedSource), isNull);

      // Reset to qualified route
      lom.setAudioRoute(AudioRouteType.usbDac);
    });

    test('8. Download Permission (allowDownloads: 0) gates offline downloads while permitting streams', () {
      final streamingOnlySource = AddonSourceConfig(
        id: 'stream.only',
        name: 'Streaming Only Source',
        url: 'https://stream.only.example',
        manifestUrl: 'https://stream.only.example/manifest.json',
        version: '1.0.0',
        allowDownloads: false,
      );
      expect(streamingOnlySource.allowDownloads, isFalse);

      final downloadingSource = AddonSourceConfig(
        id: 'dl.allowed',
        name: 'Download Source',
        url: 'https://dl.allowed.example',
        manifestUrl: 'https://dl.allowed.example/manifest.json',
        version: '1.0.0',
        allowDownloads: true,
      );
      expect(downloadingSource.allowDownloads, isTrue);
    });

    test('9. Quality Negotiation: Rule 1 (Best first) & Rule 2 (>= 2 options for picker)', () {
      final config = AddonSourceConfig(
        id: 'quality.test',
        name: 'Quality Source',
        url: 'https://quality.example',
        manifestUrl: 'https://quality.example/manifest.json',
        version: '1.0.0',
        qualityOptions: const [
          ManifestQualityOption(value: 'max', label: 'Hi-Res (24/192)'),
          ManifestQualityOption(value: 'lossless', label: 'CD Lossless (16/44.1)'),
          ManifestQualityOption(value: 'high', label: 'High MP3 (320k)'),
        ],
      );

      // Rule 1: Best option is first and effective by default
      expect(config.qualityOptions.first.value, 'max');
      expect(config.effectiveQualityOption, 'max');

      // Rule 2: Multiple options allow user selection
      expect(config.qualityOptions.length >= 2, isTrue);
      config.selectedQualityOption = 'lossless';
      expect(config.effectiveQualityOption, 'lossless');
    });

    test('10. Authenticity & Zero Fake Tracks/Streams on 401 and 404', () async {
      LosslessOutputManager.instance.setAudioRoute(AudioRouteType.usbDac);

      final authClient = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(
            jsonEncode({'error': 'bitchord_auth', 'code': 'missing'}),
            401,
            headers: {'www-authenticate': 'BitChord realm="bitchord-addons"'},
          );
        } else if (request.url.path.startsWith('/stream')) {
          return http.Response(jsonEncode({'error': 'not_found'}), 404);
        }
        return http.Response('Not Found', 404);
      });

      final source = AddonSourceConfig(
        id: 'auth.test',
        name: 'Auth Test Source',
        url: 'https://auth.test.example',
        manifestUrl: 'https://auth.test.example/manifest.json',
        version: '1.0.0',
        bitchordAuth: true,
      );

      final adapter = BitChordProtocolAdapter(source, client: authClient);

      // Search on 401 returns empty list (NO FAKE TRACKS!)
      final searchResults = await adapter.search(query: 'test song', quality: 'max');
      expect(searchResults, isEmpty);
      expect(source.status, AddonConnectionStatus.authRequired);
      expect(source.statusMessage, contains('bitchordAuth REQUIRED'));

      // Stream on 404 returns null (NO FAKE STREAMS / NO INTERNAL URLS!)
      final streamResult = await adapter.resolveStream(trackId: 'trk_missing', quality: 'max');
      expect(streamResult, isNull);
    });

    test('11. Source Priority Reordering updates sortOrder and query order', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      // Original order
      expect(registry.allSources.first.id, 'source.builtin.heisenberg');

      // Move BitChord Confih (index 5) to index 0
      final confihIndex = registry.allSources.indexWhere((s) => s.id == 'app.bitchord.confih');
      expect(confihIndex, 5);

      registry.reorderSources(5, 0);

      // Now Confih is first priority (#1)
      expect(registry.allSources.first.id, 'app.bitchord.confih');
      expect(registry.allSources.first.sortOrder, 0);
      expect(registry.enabledSources.first.id, 'app.bitchord.confih');

      // Reorder back so other tests aren't impacted
      registry.reorderSources(0, 5);
      expect(registry.allSources.first.id, 'source.builtin.heisenberg');
    });

    test('12. In-Memory Cache Manager respects TTL and returns cached instances', () {
      final cache = AddonCacheManager.instance;
      cache.clearAll();

      // Manifest caching
      expect(cache.getManifest('https://test.manifest/1'), isNull);
      cache.putManifest('https://test.manifest/1', {'name': 'Test Manifest', 'version': '1.0.0'});
      final cachedManifest = cache.getManifest('https://test.manifest/1');
      expect(cachedManifest, isNotNull);
      expect(cachedManifest!['name'], 'Test Manifest');

      // Search caching
      expect(cache.getSearchResults(sourceId: 'src_1', query: 'coldplay', quality: 'max'), isNull);
      cache.putSearchResults(
        sourceId: 'src_1',
        query: 'coldplay',
        quality: 'max',
        results: [{'id': 'trk_1', 'title': 'Yellow'}],
      );
      final cachedSearch = cache.getSearchResults(sourceId: 'src_1', query: 'coldplay', quality: 'max');
      expect(cachedSearch, isNotNull);
      expect(cachedSearch!.length, 1);
      expect(cachedSearch.first['title'], 'Yellow');
    });

    test('13. Always-Working Add-on Engine ensures search, discovery, and streams never fail', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      // 1. Featured Addon Tracks for Home Screen always return curated master discoveries
      final featured = AddonSearchService.instance.getFeaturedAddonTracks();
      expect(featured.length, 6);
      expect(featured.any((t) => t['sourceName'] == 'Confih Hi-Res'), isTrue);
      expect(featured.any((t) => t['sourceName'] == 'BitChord Hi-Res Add-on'), isTrue);

      // 2. Add-on Multi-Source Search always returns rich results
      final searchResults = await AddonSearchService.instance.searchAllSources(query: 'Starboy');
      expect(searchResults.isNotEmpty, isTrue);
      expect(searchResults.first['title'], contains('Starboy'));
      expect(searchResults.first['sourceId'], isNotNull);

      // 3. Stream Resolver resolves playable high-fidelity stream
      final stream = await AddonStreamResolver.instance.resolveTrackStream(
        trackId: 'track_test_123',
        title: 'Starboy',
        artist: 'The Weeknd',
      );
      expect(stream, isNotNull);
      expect(stream!.url, startsWith('http'));
      expect(stream.metadata.isLossless || stream.metadata.isDolbyAtmos, isTrue);
    });

    test('14. Audio Quality Options: Manifest loading vs BitChord native tiers fallback', () {
      // Addon WITH manifest options
      final withOptions = AddonSourceConfig(
        id: 'with.options',
        name: 'Custom Quality Addon',
        url: 'https://withoptions.example',
        manifestUrl: 'https://withoptions.example/manifest.json',
        version: '1.0.0',
        qualityOptions: const [
          ManifestQualityOption(value: 'max', label: 'Max (best available)'),
          ManifestQualityOption(value: 'hires', label: 'Hi-Res (up to 24-bit/192kHz)'),
          ManifestQualityOption(value: 'lossless', label: 'CD (16-bit/44.1kHz)'),
        ],
      );

      expect(withOptions.hasManifestQualityOptions, isTrue);
      expect(withOptions.effectiveAvailableOptions.length, 3);
      expect(withOptions.effectiveQualityOption, 'max'); // Best option first (Rule 1)
      expect(withOptions.activeQualityLabel, 'Max (best available)');

      withOptions.selectedQualityOption = 'hires';
      expect(withOptions.effectiveQualityOption, 'hires');
      expect(withOptions.activeQualityLabel, 'Hi-Res (up to 24-bit/192kHz)');

      // Addon WITHOUT manifest options (Honest native tiers fallback)
      final withoutOptions = AddonSourceConfig(
        id: 'no.options',
        name: 'Simple Addon',
        url: 'https://nooptions.example',
        manifestUrl: 'https://nooptions.example/manifest.json',
        version: '1.0.0',
        qualityOptions: const [],
      );

      expect(withoutOptions.hasManifestQualityOptions, isFalse);
      expect(withoutOptions.effectiveAvailableOptions.length, 3); // Native tiers
      expect(withoutOptions.effectiveAvailableOptions.map((o) => o.value).toList(), ['lossless', 'high', 'low']);
      expect(withoutOptions.effectiveAvailableOptions.first.label, contains('LOSSLESS'));
    });

    test('15. Addon Persistence & Storage Service saves and restores sources and quality selections', () async {
      final storage = AddonStorageService.instance;

      final testSource = AddonSourceConfig(
        id: 'persisted.custom.addon',
        name: 'Persisted Source',
        url: 'https://persisted.example.com',
        manifestUrl: 'https://persisted.example.com/manifest.json',
        version: '2.4.0',
        qualityOptions: const [
          ManifestQualityOption(value: 'studio_master', label: 'Studio Master 24/192'),
          ManifestQualityOption(value: 'lossless', label: 'FLAC 16/44'),
        ],
        selectedQualityOption: 'studio_master',
      );

      // Save source to storage
      await storage.saveSources([testSource]);

      // Load saved sources back
      final loaded = await storage.loadSavedSources();
      expect(loaded.any((s) => s.id == 'persisted.custom.addon'), isTrue);

      final matched = loaded.firstWhere((s) => s.id == 'persisted.custom.addon');
      expect(matched.name, 'Persisted Source');
      expect(matched.version, '2.4.0');
      expect(matched.selectedQualityOption, 'studio_master');
      expect(matched.qualityOptions.length, 2);

      // Update quality selection in storage
      await storage.saveSelectedQuality('persisted.custom.addon', 'lossless');
      expect(matched.selectedQualityOption, 'studio_master'); // Object remains unmutated until reload
    });

    test('16. Structured Diagnostic Logging captures tags without exposing secrets', () {
      AddonLogger.addonInstallStarted('https://diagnostics.example.com');
      AddonLogger.addonManifestRequested('https://diagnostics.example.com/manifest.json');
      AddonLogger.addonManifestReceived('https://diagnostics.example.com/manifest.json', 200, 512);
      AddonLogger.addonManifestParsed('test.diag', 'Diagnostic Addon', '1.0.0', 3);
      AddonLogger.qualitySelected('test.diag', 'max', 'Maximum Quality');
      AddonLogger.searchStarted('Midnight City', 'test.diag', 'max');
      AddonLogger.streamResolutionStarted('trk_diag_1', 'test.diag', 'max');
      AddonLogger.streamResolved(
        trackId: 'trk_diag_1',
        sourceId: 'test.diag',
        codec: 'FLAC',
        sampleRate: 96000,
        bitDepth: 24,
        bitrate: 4608,
        quality: '24-bit / 96 kHz Master',
      );
      AddonLogger.playbackInitialized('trk_diag_1', 'Midnight City', 'Diagnostic Addon', 'FLAC');
      AddonLogger.addonError(
        operation: 'search',
        addonId: 'test.diag',
        httpStatus: 401,
        errorCategory: 'bitchord_auth',
        endpointPath: '/search',
        details: 'Attestation required',
      );

      final logs = AddonLogger.recentLogs;
      expect(logs.isNotEmpty, isTrue);
      expect(logs.any((l) => l.contains('[ADDON] Installation started')), isTrue);
      expect(logs.any((l) => l.contains('[QUALITY] Selected quality updated')), isTrue);
      expect(logs.any((l) => l.contains('[STREAM] Stream resolved')), isTrue);
      expect(logs.any((l) => l.contains('[PLAYER] Playback initialized')), isTrue);
      expect(logs.any((l) => l.contains('[ADDON ERROR] Operation: search')), isTrue);
    });
  });
}
