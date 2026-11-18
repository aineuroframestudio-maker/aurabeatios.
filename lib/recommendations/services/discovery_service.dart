import 'package:flutter/material.dart';
import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';

/// Service generating Discover Weekly, Hidden Gems, and outside-comfort-zone discovery tracks.
class DiscoveryService {
  const DiscoveryService();

  /// Generates the Discover Weekly playlist
  PersonalizedMix generateDiscoverWeekly({
    required List<dynamic> catalog,
    required UserTasteProfile profile,
  }) {
    final historySongIds = profile.history.map((e) => e.songId).toSet();

    // Candidate discovery tracks: unplayed or rarely played tracks
    final candidates = <MapEntry<dynamic, double>>[];
    for (final song in catalog) {
      if (profile.hiddenSongIds.contains(song.id) ||
          profile.hiddenArtists.contains(song.artist)) {
        continue;
      }

      final hasPlayed = historySongIds.contains(song.id);
      final playCount = profile.history.where((e) => e.songId == song.id).length;

      // Unplayed tracks get highest novelty bonus
      double noveltyBonus = 0.0;
      if (!hasPlayed) {
        noveltyBonus = 0.35;
      } else if (playCount <= 1) {
        noveltyBonus = 0.15;
      } else {
        noveltyBonus = -0.20; // Penalize heavy rotation from Discover Weekly
      }

      final tasteAffinity = profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: _extractGenre(song),
        mood: _extractMood(song),
        year: _extractYear(song),
      );

      final discoveryScore = (tasteAffinity * 0.65) + noveltyBonus;
      candidates.add(MapEntry(song, discoveryScore));
    }

    candidates.sort((a, b) => b.value.compareTo(a.value));
    final selected = candidates.map((e) => e.key).take(12).toList();
    final cover = selected.isNotEmpty ? selected.first.coverUrl : '';

    return PersonalizedMix(
      id: 'discover_weekly',
      title: 'Discover Weekly',
      description: 'Your weekly mixtape of fresh discoveries tailored to your sonic taste',
      coverUrl: cover,
      badge: 'DISCOVERY',
      accentColor: const Color(0xFFC084FC), // Lavender / Purple
      tracks: selected,
      primaryGenre: 'Curated Discovery',
    );
  }

  /// Generates Hidden Gems and deep cuts
  List<RecommendationItem> getHiddenGems({
    required List<dynamic> catalog,
    required UserTasteProfile profile,
    int limit = 6,
  }) {
    final gems = <RecommendationItem>[];

    for (final song in catalog) {
      if (profile.hiddenSongIds.contains(song.id) ||
          profile.hiddenArtists.contains(song.artist)) {
        continue;
      }

      final popularity = _extractPopularity(song);
      final isDeepCut = popularity < 85;

      if (isDeepCut) {
        final score = profile.computeSongAffinity(
          songId: song.id,
          artist: song.artist,
          genre: _extractGenre(song),
          mood: _extractMood(song),
          year: _extractYear(song),
        );

        gems.add(RecommendationItem(
          song: song,
          score: score,
          explanation: 'Underrated gem matching your musical aesthetic',
          source: RecommendationSource.hiddenGems,
        ));
      }
    }

    gems.sort((a, b) => b.score.compareTo(a.score));
    return gems.take(limit).toList();
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
