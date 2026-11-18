import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';

/// Configurable multi-objective ranking service with diversity penalties and fatigue dampening.
class RecommendationRankingService {
  // Configurable normalized weights
  final double weightSimilarity;
  final double weightTasteAffinity;
  final double weightFreshness;
  final double weightPopularity;
  final double penaltyDiversity;

  const RecommendationRankingService({
    this.weightSimilarity = 0.40,
    this.weightTasteAffinity = 0.35,
    this.weightFreshness = 0.15,
    this.weightPopularity = 0.10,
    this.penaltyDiversity = 0.20,
  });

  /// Scores, diversifies, and ranks candidate recommendation items
  List<RecommendationItem> rankAndDiversify({
    required List<RecommendationItem> candidates,
    required UserTasteProfile profile,
    int maxPerArtist = 2,
    int limit = 20,
  }) {
    final Map<String, int> artistCounts = {};
    final List<RecommendationItem> ranked = [];

    // Filter hidden tracks/artists first
    final eligible = candidates.where((item) {
      final s = item.song;
      return !profile.hiddenSongIds.contains(s.id) &&
          !profile.hiddenArtists.contains(s.artist);
    }).toList();

    // Compute composite multi-objective score
    final scoredList = eligible.map((item) {
      final song = item.song;
      final rawSimilarity = item.score;

      final tasteScore = profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: _extractGenre(song),
        mood: _extractMood(song),
        year: _extractYear(song),
      );

      final year = _extractYear(song);
      final freshnessScore = year >= 2020 ? 1.0 : (year >= 2010 ? 0.7 : 0.4);
      final popularityScore = (_extractPopularity(song) / 100.0).clamp(0.0, 1.0);

      // Check skip fatigue in user history
      double fatiguePenalty = 0.0;
      final skipCount = profile.history.where((e) => e.songId == song.id && e.wasSkipped).length;
      if (skipCount >= 2) {
        fatiguePenalty = 0.30;
      }

      double finalScore = (rawSimilarity * weightSimilarity) +
          (tasteScore * weightTasteAffinity) +
          (freshnessScore * weightFreshness) +
          (popularityScore * weightPopularity) -
          fatiguePenalty;

      finalScore = finalScore.clamp(0.05, 1.0);

      return RecommendationItem(
        song: song,
        score: double.parse(finalScore.toStringAsFixed(3)),
        explanation: item.explanation,
        source: item.source,
        metadata: item.metadata,
      );
    }).toList();

    // Sort by composite score descending
    scoredList.sort((a, b) => b.score.compareTo(a.score));

    // Apply diversity constraint (maxPerArtist limit)
    for (final item in scoredList) {
      if (ranked.length >= limit) break;
      final artist = item.song.artist.toLowerCase();
      final currentCount = artistCounts[artist] ?? 0;

      if (currentCount < maxPerArtist) {
        artistCounts[artist] = currentCount + 1;
        ranked.add(item);
      }
    }

    // If limit not reached, backfill with remaining candidates
    if (ranked.length < limit) {
      for (final item in scoredList) {
        if (!ranked.contains(item)) {
          ranked.add(item);
          if (ranked.length >= limit) break;
        }
      }
    }

    return ranked;
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

  int _extractPopularity(dynamic song) {
    try {
      return (song.popularity as int?) ?? 80;
    } catch (_) {
      return 80;
    }
  }
}
