import 'package:flutter/material.dart';
import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';

/// Personalized new-release recommendation system prioritizing followed artists,
/// favorite artists, and top genre affinities.
class ReleaseRecommendationService {
  const ReleaseRecommendationService();

  PersonalizedMix generateReleaseRadar({
    required List<dynamic> catalog,
    required UserTasteProfile profile,
  }) {
    final candidates = <MapEntry<dynamic, double>>[];

    for (final song in catalog) {
      if (profile.hiddenSongIds.contains(song.id) ||
          profile.hiddenArtists.contains(song.artist)) {
        continue;
      }

      final year = _extractYear(song);
      // New release priority: recent releases (2020-2024+) get heavy recency boost
      double recencyMultiplier = 1.0;
      if (year >= 2022) {
        recencyMultiplier = 1.8;
      } else if (year >= 2020) {
        recencyMultiplier = 1.4;
      } else if (year >= 2015) {
        recencyMultiplier = 1.0;
      } else {
        recencyMultiplier = 0.6; // Classic releases
      }

      final artistAffinity = profile.artistAffinities[song.artist] ?? 0.25;
      final isFollowed = profile.followedArtists.contains(song.artist);
      final followedBonus = isFollowed ? 0.40 : 0.0;

      final genreAffinity = profile.genreAffinities[_extractGenre(song)] ?? 0.20;

      final radarScore = ((artistAffinity * 0.45) + (genreAffinity * 0.25) + followedBonus) * recencyMultiplier;
      candidates.add(MapEntry(song, radarScore));
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    final selected = candidates.map((e) => e.key).take(10).toList();
    final cover = selected.isNotEmpty ? selected.first.coverUrl : '';

    return PersonalizedMix(
      id: 'release_radar',
      title: 'Release Radar',
      description: 'Catch all the newest drops from artists you love and follow',
      coverUrl: cover,
      badge: 'NEW RELEASES',
      accentColor: const Color(0xFF38BDF8), // Sky blue
      tracks: selected,
      primaryGenre: 'Fresh Releases',
    );
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
}
