import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/addon_source_model.dart';
import 'addon_logger.dart';

/// Service responsible for discovering, inspecting, validating, and health-checking
/// remote add-on sources according to the official BitChord Add-on specification.
class AddonDiscoveryService {
  final http.Client _client;

  AddonDiscoveryService({http.Client? client}) : _client = client ?? http.Client();

  /// Normalizes base URL, stripping trailing slashes or manifest.json suffixes
  static String normalizeBaseUrl(String raw) {
    var trimmed = raw.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.toLowerCase().endsWith('/manifest.json')) {
      trimmed = trimmed.substring(0, trimmed.length - 14);
    }
    return trimmed;
  }

  /// Inspects a remote URL and returns verified AddonSourceConfig and capabilities
  Future<AddonSourceConfig> inspectSource(String rawUrl, {String? defaultName, bool isDefault = false}) async {
    AddonLogger.addonInstallStarted(rawUrl);

    final cleanInput = rawUrl.trim();
    final baseUrl = normalizeBaseUrl(cleanInput);

    // Candidates for manifest endpoint (prefer explicit /manifest.json, fallback to raw url / root)
    final manifestCandidates = <String>[];
    if (cleanInput.toLowerCase().endsWith('.json')) {
      manifestCandidates.add(cleanInput);
    }
    manifestCandidates.add('$baseUrl/manifest.json');
    if (!manifestCandidates.contains(baseUrl)) {
      manifestCandidates.add(baseUrl);
    }

    Map<String, dynamic>? manifestJson;
    String actualManifestUrl = '$baseUrl/manifest.json';
    String? id;
    String? name;
    String version = '1.0.0';
    List<String> resources = ['search', 'stream'];
    List<String> qualityTiers = ['Hi-Res (24-bit)', 'Lossless (16-bit)'];
    List<ManifestQualityOption> qualityOptions = [];
    String? defaultQualityOption;
    Map<String, dynamic> rawSettings = {};
    bool requiresAuth = false;
    String? authRealm;
    bool bitchordAuth = false;
    bool allowDownloads = true;
    bool checkValidLossless = false;
    String? upstreamProvider;
    Map<String, dynamic> metadata = {};

    AddonConnectionStatus status = AddonConnectionStatus.connected;
    String statusMessage = 'Operational';
    String? lastError;

    // 1. Fetch manifest.json from candidates
    for (final candidateUrl in manifestCandidates) {
      try {
        AddonLogger.addonManifestRequested(candidateUrl);
        final manifestUri = Uri.parse(candidateUrl);
        final manifestResponse = await _client.get(
          manifestUri,
          headers: {'Accept': 'application/json', 'User-Agent': 'BitChord/1.9.1 (AuraBeat-Compatible)'},
        ).timeout(const Duration(seconds: 6));

        AddonLogger.addonManifestReceived(candidateUrl, manifestResponse.statusCode, manifestResponse.bodyBytes.length);

        if (manifestResponse.statusCode == 200) {
          try {
            final decoded = jsonDecode(manifestResponse.body);
            if (decoded is Map) {
              manifestJson = Map<String, dynamic>.from(decoded);
              actualManifestUrl = candidateUrl;
              metadata['manifest'] = manifestJson;
              break;
            }
          } catch (e) {
            AddonLogger.addonError(
              operation: 'manifest_json_parse',
              errorCategory: 'syntax',
              endpointPath: candidateUrl,
              details: 'Invalid JSON in manifest: $e',
            );
          }
        }
      } catch (e) {
        AddonLogger.addonError(
          operation: 'manifest_request',
          errorCategory: 'network',
          endpointPath: candidateUrl,
          details: e.toString(),
        );
      }
    }

    // 2. Parse and Validate Manifest Fields
    if (manifestJson != null) {
      id = manifestJson['id']?.toString().trim();
      name = manifestJson['name']?.toString() ?? name;
      version = manifestJson['version']?.toString() ?? version;

      // BitChord Rule: An empty or missing id is rejected
      if (id == null || id.isEmpty) {
        lastError = 'That URL answered, but not with an addon manifest (missing or empty id)';
        status = AddonConnectionStatus.offline;
        statusMessage = lastError;
        AddonLogger.addonError(
          operation: 'manifest_validation',
          errorCategory: 'schema',
          details: 'Manifest has no non-empty "id" field',
        );
      }

      if (manifestJson.containsKey('resources') && manifestJson['resources'] is List) {
        resources = (manifestJson['resources'] as List).map((e) => e.toString()).toList();
      }

      if (manifestJson.containsKey('bitchordAuth')) {
        bitchordAuth = manifestJson['bitchordAuth'] == true || manifestJson['bitchordAuth'] == 1;
        requiresAuth = bitchordAuth;
      }

      if (manifestJson.containsKey('allowDownloads')) {
        allowDownloads = manifestJson['allowDownloads'] == 1 || manifestJson['allowDownloads'] == true;
      }

      if (manifestJson.containsKey('checkValidLossless')) {
        checkValidLossless = manifestJson['checkValidLossless'] == 1 || manifestJson['checkValidLossless'] == true;
      }

      // Settings & Quality Options parsing (BitChord specification)
      if (manifestJson.containsKey('settings')) {
        final rawSettingsObj = manifestJson['settings'];
        final List<dynamic> settingsList = rawSettingsObj is List
            ? rawSettingsObj
            : (rawSettingsObj is Map ? rawSettingsObj.values.toList() : []);

        for (final s in settingsList) {
          if (s is Map) {
            final key = s['key']?.toString();
            if (key != null) {
              rawSettings[key] = s;
            }
            if ((key == 'quality' || key == 'audioQuality') && s['options'] is List) {
              defaultQualityOption = s['default']?.toString();
              final optsList = s['options'] as List;
              final parsedOptions = <ManifestQualityOption>[];

              for (final opt in optsList) {
                if (opt is Map) {
                  final val = opt['value']?.toString() ?? '';
                  final lbl = opt['label']?.toString() ?? val;
                  if (val.isNotEmpty) {
                    parsedOptions.add(ManifestQualityOption(value: val, label: lbl));
                  }
                } else if (opt != null) {
                  final str = opt.toString().trim();
                  if (str.isNotEmpty) {
                    parsedOptions.add(ManifestQualityOption(value: str, label: str));
                  }
                }
              }

              if (parsedOptions.isNotEmpty) {
                qualityOptions = parsedOptions;
                qualityTiers = parsedOptions.map((o) => o.label).toList();
                AddonLogger.qualityOptionsLoaded(id ?? baseUrl, parsedOptions.map((o) => o.toString()).toList());
              }
            }
          }
        }
      }

      // BitChord Fallback: If quality options were not nested inside settings, check top-level quality array
      if (qualityOptions.isEmpty && manifestJson.containsKey('quality') && manifestJson['quality'] is List) {
        final optsList = manifestJson['quality'] as List;
        final parsedOptions = <ManifestQualityOption>[];
        for (final opt in optsList) {
          if (opt is Map) {
            final val = opt['value']?.toString() ?? '';
            final lbl = opt['label']?.toString() ?? val;
            if (val.isNotEmpty) {
              parsedOptions.add(ManifestQualityOption(value: val, label: lbl));
            }
          } else if (opt != null) {
            final str = opt.toString().trim();
            if (str.isNotEmpty) {
              parsedOptions.add(ManifestQualityOption(value: str, label: str));
            }
          }
        }
        if (parsedOptions.isNotEmpty) {
          qualityOptions = parsedOptions;
          qualityTiers = parsedOptions.map((o) => o.label).toList();
          defaultQualityOption = parsedOptions.first.value;
          AddonLogger.qualityOptionsLoaded(id ?? baseUrl, parsedOptions.map((o) => o.toString()).toList());
        }
      }

      AddonLogger.addonManifestParsed(id ?? 'unknown', name ?? 'Unnamed', version, qualityOptions.length);
    } else {
      lastError = 'Unable to fetch a valid addon manifest from $rawUrl';
      status = AddonConnectionStatus.offline;
      statusMessage = 'Unreachable: No manifest found';
      AddonLogger.addonError(
        operation: 'inspect_source',
        errorCategory: 'manifest_not_found',
        endpointPath: baseUrl,
        details: 'None of the candidate endpoints returned a valid manifest',
      );
    }

    // 3. Probe search endpoint for live contract check and bitchordAuth verification
    if (status != AddonConnectionStatus.offline) {
      try {
        final searchUri = Uri.parse('$baseUrl/search').replace(queryParameters: {'q': 'test'});
        final searchResponse = await _client.get(
          searchUri,
          headers: {'Accept': 'application/json', 'User-Agent': 'BitChord/1.9.1 (AuraBeat-Compatible)'},
        ).timeout(const Duration(seconds: 4));

        if (searchResponse.statusCode == 401) {
          requiresAuth = true;
          bitchordAuth = true;
          final authHeader = searchResponse.headers['www-authenticate'];
          if (authHeader != null && authHeader.contains('realm=')) {
            authRealm = authHeader;
          }
          status = AddonConnectionStatus.authRequired;
          statusMessage = 'bitchordAuth REQUIRED · Hardware Key Attestation needed';
          AddonLogger.addonError(
            operation: 'search_auth_probe',
            addonId: id,
            httpStatus: 401,
            errorCategory: 'bitchord_auth',
            endpointPath: '/search',
            details: 'Protected by official BitChord hardware proof',
          );
        } else if (searchResponse.statusCode == 200) {
          status = AddonConnectionStatus.connected;
          statusMessage = 'Operational · Live search verified';
        } else {
          status = AddonConnectionStatus.connected;
          statusMessage = 'Operational (HTTP ${searchResponse.statusCode})';
        }
      } catch (e) {
        // Search endpoint failure should NOT mark the addon offline if manifest was verified
        if (manifestJson != null) {
          status = AddonConnectionStatus.connected;
          statusMessage = 'Operational · Manifest v$version verified';
        }
      }
    }

    final finalId = (id != null && id.isNotEmpty)
        ? id
        : 'source.${Uri.parse(baseUrl).host.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final finalName = (name != null && name.isNotEmpty)
        ? name
        : (defaultName ?? Uri.parse(baseUrl).host);

    return AddonSourceConfig(
      id: finalId,
      name: finalName,
      url: baseUrl,
      manifestUrl: actualManifestUrl,
      version: version,
      isDefault: isDefault,
      isEnabled: true,
      status: status,
      statusMessage: statusMessage,
      lastRefreshed: DateTime.now(),
      lastError: lastError,
      resources: resources,
      qualityTiers: qualityTiers,
      qualityOptions: qualityOptions,
      selectedQualityOption: defaultQualityOption,
      requiresAuth: requiresAuth,
      authRealm: authRealm ?? (bitchordAuth ? 'BitChord realm="bitchord-addons"' : null),
      bitchordAuth: bitchordAuth,
      allowDownloads: allowDownloads,
      checkValidLossless: checkValidLossless,
      upstreamProvider: upstreamProvider,
      rawSettings: rawSettings,
      metadata: metadata,
    );
  }
}
