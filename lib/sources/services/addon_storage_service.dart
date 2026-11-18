import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/addon_source_model.dart';
import 'addon_logger.dart';

/// Local persistence service for AuraBeat add-on source configurations,
/// user-installed sources, enabled states, priority ordering, and per-addon quality choices.
class AddonStorageService {
  static final AddonStorageService instance = AddonStorageService._internal();

  final Map<String, dynamic> _memoryStore = {};
  File? _storageFile;
  bool _initialized = false;

  AddonStorageService._internal();

  /// Determine the appropriate file path for storing add-on data
  Future<File?> _resolveStorageFile() async {
    if (kIsWeb) return null;
    try {
      String? dirPath;
      if (Platform.isWindows) {
        dirPath = Platform.environment['APPDATA'] ?? Platform.environment['LOCALAPPDATA'];
      } else if (Platform.isAndroid || Platform.isIOS || Platform.isLinux || Platform.isMacOS) {
        dirPath = Platform.environment['HOME'] ?? Directory.systemTemp.path;
      }
      dirPath ??= Directory.systemTemp.path;

      final auraDir = Directory('$dirPath/AuraBeat');
      if (!await auraDir.exists()) {
        await auraDir.create(recursive: true);
      }
      return File('${auraDir.path}/installed_addons.json');
    } catch (e) {
      debugPrint('[AddonStorage] File path resolution fallback to temp: $e');
      try {
        return File('${Directory.systemTemp.path}/aurabeat_installed_addons.json');
      } catch (_) {
        return null;
      }
    }
  }

  /// Initialize storage
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    _storageFile = await _resolveStorageFile();
  }

  /// Load persisted custom addons and source settings
  Future<List<AddonSourceConfig>> loadSavedSources() async {
    await init();
    if (_storageFile != null && await _storageFile!.exists()) {
      try {
        final raw = await _storageFile!.readAsString();
        if (raw.trim().isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            final sources = <AddonSourceConfig>[];
            for (final item in decoded) {
              if (item is Map) {
                try {
                  final config = AddonSourceConfig.fromJson(Map<String, dynamic>.from(item));
                  sources.add(config);
                  AddonLogger.addonLoadedIntoUI(config.id, config.name);
                } catch (e) {
                  AddonLogger.addonError(
                    operation: 'load_saved_sources',
                    errorCategory: 'deserialization',
                    details: 'Failed to parse source: $e',
                  );
                }
              }
            }
            return sources;
          }
        }
      } catch (e) {
        AddonLogger.addonError(
          operation: 'read_storage_file',
          errorCategory: 'io',
          details: 'Error reading ${_storageFile?.path}: $e',
        );
      }
    }

    // Fallback to memory store if present
    if (_memoryStore.containsKey('sources')) {
      final list = _memoryStore['sources'] as List<dynamic>;
      return list
          .whereType<Map>()
          .map((m) => AddonSourceConfig.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return [];
  }

  /// Save all current sources (including default states and custom installed addons)
  Future<void> saveSources(List<AddonSourceConfig> sources) async {
    await init();
    final jsonList = sources.map((s) => s.toJson()).toList();
    _memoryStore['sources'] = jsonList;

    if (_storageFile != null) {
      try {
        final encoded = jsonEncode(jsonList);
        await _storageFile!.writeAsString(encoded, flush: true);
        AddonLogger.addonSaved('all_sources', '${sources.length} sources persisted');
      } catch (e) {
        AddonLogger.addonError(
          operation: 'write_storage_file',
          errorCategory: 'io',
          details: 'Error writing to ${_storageFile?.path}: $e',
        );
      }
    }
  }

  /// Save user's selected quality option for a specific addon
  Future<void> saveSelectedQuality(String sourceId, String optionValue) async {
    await init();
    _memoryStore['quality_$sourceId'] = optionValue;
    if (_storageFile != null && await _storageFile!.exists()) {
      try {
        final sources = await loadSavedSources();
        final match = sources.indexWhere((s) => s.id == sourceId);
        if (match != -1) {
          sources[match].selectedQualityOption = optionValue;
          await saveSources(sources);
        }
      } catch (_) {}
    }
  }
}
