import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';
import 'track_similarity_service.dart';

/// Intelligent next-track predictive generator powering queue continuation and autoplay.
class AutoplayRecommendationService {
  final TrackSimilarityService _trackSimilarity;

  const AutoplayRecommendationService({
    TrackSimilarityService trackSimilarity = const TrackSimilarityService(),
  }) : _trackSimilarity = trackSimilarity;

  /// Predicts the single best next track when the queue reaches its end
  dynamic getNextAutoplayTrack({
    required dynamic currentSong,
    required List<dynamic> catalog,
    required UserTasteProfile profile,
    required List<String> sessionPlayedSongIds,
  }) {
    if (!profile.autoplayEnabled) return null;

    final candidates = <MapEntry<dynamic, double>>[];

    for (final song in catalog) {
      // Avoid current song and already played songs in this session
      if (song.id == currentSong.id) continue;
      if (sessionPlayedSongIds.contains(song.id)) continue;
      if (profile.hiddenSongIds.contains(song.id) ||
          profile.hiddenArtists.contains(song.artist)) {
        continue;
      }

      // Compute acoustic transition similarity
      final transitionSim = _trackSimilarity.computeSimilarity(currentSong, song);

      // Compute user preference alignment
      final tasteAffinity = profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: _extractGenre(song),
        mood: _extractMood(song),
        year: _extractYear(song),
      );

      // Blend: 55% musical flow transition + 45% listener taste affinity
      final autoplayScore = (transitionSim * 0.55) + (tasteAffinity * 0.45);
      candidates.add(MapEntry(song, autoplayScore));
    }

    if (candidates.isEmpty) {
      // Fallback: pick any track from catalog that isn't currentSong
      return catalog.firstWhere((s) => s.id != currentSong.id, orElse: () => currentSong);
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    return candidates.first.key;
  }

  /// Supplies upcoming queue suggestions (for queue view "Recommended Next")
  List<RecommendationItem> getQueueSuggestions({
    required dynamic currentSong,
    required List<dynamic> catalog,
    required UserTasteProfile profile,
    required List<String> currentQueueIds,
    int count = 5,
  }) {
    final list = <RecommendationItem>[];

    for (final song in catalog) {
      if (currentQueueIds.contains(song.id)) continue;
      if (profile.hiddenSongIds.contains(song.id) ||
          profile.hiddenArtists.contains(song.artist)) {
        continue;
      }

      final sim = _trackSimilarity.computeSimilarity(currentSong, song);
      final aff = profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: _extractGenre(song),
        mood: _extractMood(song),
        year: _extractYear(song),
      );

      final score = (sim * 0.6) + (aff * 0.4);
      list.add(RecommendationItem(
        song: song,
        score: score,
        explanation: 'Recommended to keep the groove flowing',
        source: RecommendationSource.autoplay,
      ));
    }

    list.sort((a, b) => b.score.compareTo(a.score));
    return list.take(count).toList();
  }

  String _extractGenre(dynamic song) {
    try {
      return (song.genre as String?) ?? 'Electronic';
    } catch (_) {
      return 'Electronic';
    }
  }

  String _extractMood(dynamic song) {
    try {
      return (song.mood as String?) ?? 'Energetic';
    } catch (_) {
      return 'Energetic';
    }
  }

  int _extractYear(dynamic song) {
    try {
      return (song.year as int?) ?? 2018;
    } catch (_) {
      return 2018;
    }
  }
}
