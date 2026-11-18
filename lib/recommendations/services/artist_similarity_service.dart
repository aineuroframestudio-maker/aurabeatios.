import 'dart:math';
import '../models/user_taste_profile.dart';

/// Service calculating artist similarity and providing artist-based discovery
class ArtistSimilarityService {
  const ArtistSimilarityService();

  /// Computes similarity score between two artists (0.0 to 1.0)
  double computeArtistSimilarity(dynamic a, dynamic b) {
    if (a.id == b.id || a.name.toLowerCase() == b.name.toLowerCase()) {
      return 1.0;
    }

    final genreA = a.genre.toLowerCase();
    final genreB = b.genre.toLowerCase();

    // Tokenize genres
    final tokensA = genreA.split(RegExp(r'[\s/]+')).toSet();
    final tokensB = genreB.split(RegExp(r'[\s/]+')).toSet();
    final intersection = tokensA.intersection(tokensB).length;
    final union = tokensA.union(tokensB).length;

    double jaccard = union > 0 ? (intersection / union) : 0.0;

    // Explicit known synergy/influence relationships
    final nameA = a.name.toLowerCase();
    final nameB = b.name.toLowerCase();
    if ((nameA.contains('daft punk') && nameB.contains('the weeknd')) ||
        (nameA.contains('the weeknd') && nameB.contains('daft punk'))) {
      jaccard = max(jaccard, 0.85);
    }
    if ((nameA.contains('m83') && nameB.contains('kavinsky')) ||
        (nameA.contains('kavinsky') && nameB.contains('m83'))) {
      jaccard = max(jaccard, 0.78);
    }
    if ((nameA.contains('tame impala') && nameB.contains('m83')) ||
        (nameA.contains('m83') && nameB.contains('tame impala'))) {
      jaccard = max(jaccard, 0.75);
    }
    if ((nameA.contains('chvrches') && nameB.contains('m83')) ||
        (nameA.contains('m83') && nameB.contains('chvrches'))) {
      jaccard = max(jaccard, 0.72);
    }

    return jaccard.clamp(0.15, 1.0);
  }

  /// Returns ranked similar artists for a given artist name
  List<dynamic> getSimilarArtists(
    String artistName,
    List<dynamic> allArtists, {
    int limit = 5,
    UserTasteProfile? profile,
  }) {
    dynamic seedArtist;
    for (final ar in allArtists) {
      if (ar.name.toLowerCase() == artistName.toLowerCase()) {
        seedArtist = ar;
        break;
      }
    }
    seedArtist ??= (allArtists.isNotEmpty ? allArtists.first : null);
    if (seedArtist == null) return [];

    final candidates = allArtists.where((ar) => ar.id != seedArtist.id).toList();

    candidates.sort((a, b) {
      double scoreA = computeArtistSimilarity(seedArtist, a);
      double scoreB = computeArtistSimilarity(seedArtist, b);
      if (profile != null) {
        scoreA += (profile.artistAffinities[a.name] ?? 0.0) * 0.25;
        scoreB += (profile.artistAffinities[b.name] ?? 0.0) * 0.25;
      }
      return scoreB.compareTo(scoreA);
    });

    return candidates.take(limit).toList();
  }

  /// Get essential/top popular tracks by an artist
  List<dynamic> getEssentialTracks(String artistName, List<dynamic> catalog, {int limit = 4}) {
    final lowerName = artistName.toLowerCase();
    final matches = catalog.where((s) => s.artist.toLowerCase().contains(lowerName)).toList();
    matches.sort((a, b) {
      final popA = _extractPopularity(a);
      final popB = _extractPopularity(b);
      return popB.compareTo(popA);
    });
    return matches.take(limit).toList();
  }

  /// Get deep cuts / underrated tracks for an artist
  List<dynamic> getDeepCuts(String artistName, List<dynamic> catalog, {int limit = 3}) {
    final lowerName = artistName.toLowerCase();
    final matches = catalog.where((s) => s.artist.toLowerCase().contains(lowerName)).toList();
    if (matches.length <= 1) return matches;
    matches.sort((a, b) {
      final popA = _extractPopularity(a);
      final popB = _extractPopularity(b);
      return popA.compareTo(popB); // Ascending popularity for deep cuts
    });
    return matches.take(limit).toList();
  }

  int _extractPopularity(dynamic song) {
    try {
      return (song.popularity as int?) ?? 80;
    } catch (_) {
      return 80;
    }
  }
}
