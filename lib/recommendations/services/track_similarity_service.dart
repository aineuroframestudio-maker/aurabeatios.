import 'dart:math';
import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';

/// Multi-attribute track similarity calculator and 'More Like This' recommendation engine.
class TrackSimilarityService {
  const TrackSimilarityService();

  /// Computes hybrid acoustic and metadata similarity between track A and track B (0.0 to 1.0)
  double computeSimilarity(dynamic a, dynamic b) {
    if (a.id == b.id) return 1.0;

    // 1. Artist similarity (weight: 0.32)
    final double artistSim = _computeArtistSimilarity(a.artist, b.artist);

    // 2. Genre & subgenre overlap (weight: 0.28)
    final double genreSim = _computeGenreSimilarity(a, b);

    // 3. Era / Year proximity (weight: 0.12)
    final int yearA = _extractYear(a);
    final int yearB = _extractYear(b);
    final double yearDelta = (yearA - yearB).abs().toDouble();
    final double eraSim = exp(-pow(yearDelta / 8.0, 2));

    // 4. Tempo / BPM similarity (weight: 0.14)
    final int bpmA = _extractBpm(a);
    final int bpmB = _extractBpm(b);
    final double bpmDelta = (bpmA - bpmB).abs().toDouble();
    final double bpmSim = exp(-bpmDelta / 35.0);

    // 5. Mood / Vibe affinity (weight: 0.08)
    final String moodA = _extractMood(a);
    final String moodB = _extractMood(b);
    final double moodSim = _computeMoodSimilarity(moodA, moodB);

    // 6. Language compatibility (weight: 0.06)
    final String langA = _extractLanguage(a);
    final String langB = _extractLanguage(b);
    final double langSim = (langA == langB) ? 1.0 : 0.40;

    final double composite = (artistSim * 0.32) +
        (genreSim * 0.28) +
        (bpmSim * 0.14) +
        (eraSim * 0.12) +
        (moodSim * 0.08) +
        (langSim * 0.06);

    return composite.clamp(0.0, 1.0);
  }

  /// Returns ranked similar songs matching the seed song
  List<RecommendationItem> getSimilarSongs(
    dynamic seed,
    List<dynamic> catalog, {
    int limit = 10,
    UserTasteProfile? profile,
  }) {
    final List<RecommendationItem> results = [];

    for (final song in catalog) {
      if (song.id == seed.id) continue;
      if (profile != null &&
          (profile.hiddenSongIds.contains(song.id) ||
              profile.hiddenArtists.contains(song.artist))) {
        continue;
      }

      double sim = computeSimilarity(seed, song);

      // Blend with user taste profile affinity if provided
      if (profile != null && profile.recommendationsEnabled) {
        final tasteAffinity = profile.computeSongAffinity(
          songId: song.id,
          artist: song.artist,
          genre: _extractGenre(song),
          mood: _extractMood(song),
          year: _extractYear(song),
          language: _extractLanguage(song),
        );
        sim = (sim * 0.70) + (tasteAffinity * 0.30);
      }

      final explanation = _generateExplanation(seed, song, sim);
      results.add(RecommendationItem(
        song: song,
        score: double.parse(sim.toStringAsFixed(3)),
        explanation: explanation,
        source: RecommendationSource.songSeed,
      ));
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  /// Returns 'More Like This' recommendations for song detail view
  List<RecommendationItem> getMoreLikeThis(dynamic seed, List<dynamic> catalog, {int limit = 6}) {
    return getSimilarSongs(seed, catalog, limit: limit);
  }

  // --- Private Helpers ---

  double _computeArtistSimilarity(String a, String b) {
    if (a.toLowerCase() == b.toLowerCase()) return 1.0;
    // Check if one features the other or shares collaborators
    final lowerA = a.toLowerCase();
    final lowerB = b.toLowerCase();
    if (lowerA.contains(lowerB) || lowerB.contains(lowerA)) return 0.75;
    if (lowerA.contains('daft punk') && lowerB.contains('the weeknd')) return 0.70;
    if (lowerA.contains('the weeknd') && lowerB.contains('daft punk')) return 0.70;
    if (lowerA.contains('m83') && lowerB.contains('kavinsky')) return 0.65;
    if (lowerA.contains('kavinsky') && lowerB.contains('m83')) return 0.65;
    return 0.15;
  }

  double _computeGenreSimilarity(dynamic a, dynamic b) {
    final genreA = _extractGenre(a).toLowerCase();
    final genreB = _extractGenre(b).toLowerCase();
    if (genreA == genreB) return 1.0;

    // Subgenre token Jaccard similarity
    final tokensA = genreA.split(RegExp(r'[\s/]+')).toSet();
    final tokensB = genreB.split(RegExp(r'[\s/]+')).toSet();
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;

    if (union == 0) return 0.10;
    final jaccard = intersection / union;
    return (jaccard * 0.8 + 0.2).clamp(0.1, 1.0);
  }

  double _computeMoodSimilarity(String a, String b) {
    if (a.toLowerCase() == b.toLowerCase()) return 1.0;
    final compatible = {
      'energetic': ['euphoric', 'party'],
      'chill': ['relax', 'late night', 'peaceful'],
      'late night': ['chill', 'nostalgic', 'atmospheric'],
      'euphoric': ['energetic', 'party', 'uplifting'],
    };
    final key = a.toLowerCase();
    if (compatible.containsKey(key) && compatible[key]!.contains(b.toLowerCase())) {
      return 0.65;
    }
    return 0.25;
  }

  String _generateExplanation(dynamic seed, dynamic candidate, double score) {
    if (seed.artist.toLowerCase() == candidate.artist.toLowerCase()) {
      return 'More essential tracks by ${seed.artist}';
    }
    final genre = _extractGenre(candidate);
    final seedGenre = _extractGenre(seed);
    if (genre == seedGenre) {
      return 'Similar $genre sonic texture & tempo';
    }
    if (_computeArtistSimilarity(seed.artist, candidate.artist) > 0.6) {
      return 'Because you listen to ${seed.artist}';
    }
    return 'Harmonically compatible with ${seed.title}';
  }

  String _extractGenre(dynamic song) {
    try {
      return (song.genre as String?) ?? 'Electronic';
    } catch (_) {
      return 'Electronic';
    }
  }

  int _extractYear(dynamic song) {
    try {
      return (song.year as int?) ?? 2018;
    } catch (_) {
      return 2018;
    }
  }

  int _extractBpm(dynamic song) {
    try {
      return (song.bpm as int?) ?? 120;
    } catch (_) {
      return 120;
    }
  }

  String _extractMood(dynamic song) {
    try {
      return (song.mood as String?) ?? 'Energetic';
    } catch (_) {
      return 'Energetic';
    }
  }

  String _extractLanguage(dynamic song) {
    try {
      return (song.language as String?) ?? 'English';
    } catch (_) {
      return 'English';
    }
  }
}
