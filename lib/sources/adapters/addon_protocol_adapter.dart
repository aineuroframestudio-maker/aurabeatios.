import '../models/addon_source_model.dart';
import '../models/audio_quality_models.dart';

/// Abstract adapter interface for any audio add-on provider.
/// Allows BitChord, custom REST, WebDAV, or self-hosted audio sources
/// to plug into AuraBeat without vendor lock-in or fragile coupling.
abstract class AddonProtocolAdapter {
  final AddonSourceConfig config;

  AddonProtocolAdapter(this.config);

  /// Health check / ping
  Future<AddonConnectionStatus> checkHealth();

  /// Search query with quality & atmos negotiation
  Future<List<Map<String, dynamic>>> search({
    required String query,
    required String quality,
    String? atmos,
    int limit = 20,
  });

  /// Resolve audio stream with quality & atmos negotiation
  Future<ResolvedStream?> resolveStream({
    required String trackId,
    required String quality,
    String? atmos,
  });
}
