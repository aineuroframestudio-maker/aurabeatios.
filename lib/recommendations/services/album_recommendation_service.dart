import 'dart:math';
import '../models/user_taste_profile.dart';

/// Service generating personalized album recommendations and similar album discovery.
class AlbumRecommendationService {
  const AlbumRecommendationService();

  /// Returns albums similar to the seed album
  List<dynamic> getSimilarAlbums(dynamic seedAlbum, List<dynamic> allAlbums, {int limit = 4}) {
    final candidates = allAlbums.where((a) => a.id != seedAlbum.id).toList();

    candidates.sort((a, b) {
      double scoreA = _computeAlbumSimilarity(seedAlbum, a);
      double scoreB = _computeAlbumSimilarity(seedAlbum, b);
      return scoreB.compareTo(scoreA);
    });

    return candidates.take(limit).toList();
  }

  /// Recommends albums tailored to the user's taste profile
  List<dynamic> getPersonalizedAlbums(
    UserTasteProfile profile,
    List<dynamic> allAlbums, {
    int limit = 6,
  }) {
    final list = List<dynamic>.from(allAlbums);

    list.sort((a, b) {
      double scoreA = _computeTasteScore(profile, a);
      double scoreB = _computeTasteScore(profile, b);
      return scoreB.compareTo(scoreA);
    });

    return list.take(limit).toList();
  }

  double _computeAlbumSimilarity(dynamic a, dynamic b) {
    double score = 0.0;
    if (a.artist.toLowerCase() == b.artist.toLowerCase()) {
      score += 0.50; // Same artist bonus
    }

    final tokensA = a.genre.toLowerCase().split(RegExp(r'[\s/]+')).toSet();
    final tokensB = b.genre.toLowerCase().split(RegExp(r'[\s/]+')).toSet();
    final inter = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;
    final jaccard = union > 0 ? (inter / union) : 0.0;
    score += jaccard * 0.35;

    final yearA = int.tryParse(a.year) ?? 2015;
    final yearB = int.tryParse(b.year) ?? 2015;
    final yearDelta = (yearA - yearB).abs();
    score += exp(-pow(yearDelta / 10.0, 2)) * 0.15;

    return score.clamp(0.0, 1.0);
  }

  double _computeTasteScore(UserTasteProfile profile, dynamic album) {
    if (profile.hiddenArtists.contains(album.artist)) return 0.0;

    double score = 0.20; // baseline
    if (profile.savedAlbumIds.contains(album.id)) {
      score += 0.30;
    }
    final artistScore = profile.artistAffinities[album.artist] ?? 0.20;
    score += artistScore * 0.35;

    for (final entry in profile.genreAffinities.entries) {
      if (album.genre.toLowerCase().contains(entry.key.toLowerCase())) {
        score += entry.value * 0.25;
        break;
      }
    }
    return score.clamp(0.0, 1.0);
  }
}
