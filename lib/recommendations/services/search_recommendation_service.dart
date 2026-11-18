import 'dart:math';
import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';
import 'track_similarity_service.dart';
import 'artist_similarity_service.dart';

/// Intelligent search intelligence, fuzzy typo-tolerant matching, suggestions,
/// and contextual search-based music recommendation engine.
class SearchRecommendationService {
  final TrackSimilarityService _trackSimilarity;
  final ArtistSimilarityService _artistSimilarity;

  const SearchRecommendationService({
    TrackSimilarityService trackSimilarity = const TrackSimilarityService(),
    ArtistSimilarityService artistSimilarity = const ArtistSimilarityService(),
  })  : _trackSimilarity = trackSimilarity,
        _artistSimilarity = artistSimilarity;

  /// Performs fuzzy, intelligent search across songs, artists, and albums
  SearchRecommendationResult search({
    required String query,
    required List<dynamic> songs,
    required List<dynamic> artists,
    required List<dynamic> albums,
    required UserTasteProfile profile,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return SearchRecommendationResult(
        matchingSongs: [],
        similarSongs: [],
        matchingArtists: [],
        similarArtists: [],
        matchingAlbums: [],
        relatedAlbums: [],
        suggestedQueries: profile.recentSearches.take(6).toList(),
        recommendedForYou: _getTopRecommendations(songs, profile, limit: 6),
        detectedCategory: 'all',
      );
    }

    // 1. Detect Category intent
    final detectedCategory = _detectCategory(cleanQuery, songs, artists, albums);

    // 2. Matching Songs with fuzzy scoring
    final scoredSongs = <MapEntry<dynamic, double>>[];
    for (final song in songs) {
      if (profile.hiddenSongIds.contains(song.id) ||
          profile.hiddenArtists.contains(song.artist)) {
        continue;
      }
      final score = _matchScore(cleanQuery, song.title, song.artist, song.album, _extractGenre(song));
      if (score > 0.28) {
        scoredSongs.add(MapEntry(song, score));
      }
    }
    scoredSongs.sort((a, b) => b.value.compareTo(a.value));
    final matchingSongs = scoredSongs.map((e) => e.key).toList();

    // 3. Matching Artists with fuzzy scoring
    final scoredArtists = <MapEntry<dynamic, double>>[];
    for (final artist in artists) {
      if (profile.hiddenArtists.contains(artist.name)) continue;
      final score = _matchScore(cleanQuery, artist.name, artist.genre);
      if (score > 0.30) {
        scoredArtists.add(MapEntry(artist, score));
      }
    }
    scoredArtists.sort((a, b) => b.value.compareTo(a.value));
    final matchingArtists = scoredArtists.map((e) => e.key).toList();

    // 4. Matching Albums
    final scoredAlbums = <MapEntry<dynamic, double>>[];
    for (final album in albums) {
      if (profile.hiddenArtists.contains(album.artist)) continue;
      final score = _matchScore(cleanQuery, album.title, album.artist, album.genre);
      if (score > 0.30) {
        scoredAlbums.add(MapEntry(album, score));
      }
    }
    scoredAlbums.sort((a, b) => b.value.compareTo(a.value));
    final matchingAlbums = scoredAlbums.map((e) => e.key).toList();

    // 5. Best Match Determination
    dynamic bestSong = matchingSongs.isNotEmpty ? matchingSongs.first : null;
    dynamic bestArtist = matchingArtists.isNotEmpty ? matchingArtists.first : null;
    dynamic bestAlbum = matchingAlbums.isNotEmpty ? matchingAlbums.first : null;

    // Pick supreme best match
    double bestSongScore = scoredSongs.isNotEmpty ? scoredSongs.first.value : 0.0;
    double bestArtistScore = scoredArtists.isNotEmpty ? scoredArtists.first.value : 0.0;
    double bestAlbumScore = scoredAlbums.isNotEmpty ? scoredAlbums.first.value : 0.0;

    // If query is an exact match for artist name, prioritize artist
    if (bestArtist != null && bestArtist.name.toLowerCase() == cleanQuery) {
      bestSong = null;
      bestAlbum = null;
    } else if (bestSongScore >= bestArtistScore && bestSongScore >= bestAlbumScore) {
      bestArtist = null;
      bestAlbum = null;
    }

    // 6. Search-based similar songs recommendations
    final similarSongs = <dynamic>[];
    if (bestSong != null) {
      final sim = _trackSimilarity.getSimilarSongs(bestSong, songs, limit: 6, profile: profile);
      similarSongs.addAll(sim.map((e) => e.song));
    } else if (matchingSongs.isNotEmpty) {
      final sim = _trackSimilarity.getSimilarSongs(matchingSongs.first, songs, limit: 6, profile: profile);
      similarSongs.addAll(sim.map((e) => e.song));
    }

    // 7. Search-based similar artists recommendations
    final similarArtists = <dynamic>[];
    if (bestArtist != null) {
      similarArtists.addAll(_artistSimilarity.getSimilarArtists(bestArtist.name, artists, limit: 4, profile: profile));
    } else if (matchingArtists.isNotEmpty) {
      similarArtists.addAll(_artistSimilarity.getSimilarArtists(matchingArtists.first.name, artists, limit: 4, profile: profile));
    }

    // 8. Search suggestions / autocomplete
    final suggestions = _generateSuggestions(cleanQuery, songs, artists, albums);

    // 9. Contextual Search Recommendations
    final recommendedForYou = <RecommendationItem>[];
    for (final song in songs) {
      if (matchingSongs.contains(song)) continue;
      final tasteScore = profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: _extractGenre(song),
        mood: _extractMood(song),
        year: _extractYear(song),
      );
      if (tasteScore > 0.40) {
        recommendedForYou.add(RecommendationItem(
          song: song,
          score: tasteScore,
          explanation: 'Recommended based on your interest in "$query"',
          source: RecommendationSource.searchQuery,
        ));
      }
    }
    recommendedForYou.sort((a, b) => b.score.compareTo(a.score));

    // Learn from search in background
    String? matchedGenre;
    if (detectedCategory == 'genre') matchedGenre = query;
    String? matchedArtistName;
    if (bestArtist != null) matchedArtistName = bestArtist.name;
    profile.recordSearch(query, matchedGenre: matchedGenre, matchedArtist: matchedArtistName);

    return SearchRecommendationResult(
      bestMatchSong: bestSong,
      bestMatchArtist: bestArtist,
      bestMatchAlbum: bestAlbum,
      matchingSongs: matchingSongs,
      similarSongs: similarSongs,
      matchingArtists: matchingArtists,
      similarArtists: similarArtists,
      matchingAlbums: matchingAlbums,
      relatedAlbums: matchingAlbums.isNotEmpty ? matchingAlbums.skip(1).take(4).toList() : [],
      suggestedQueries: suggestions,
      recommendedForYou: recommendedForYou.take(6).toList(),
      detectedCategory: detectedCategory,
    );
  }

  // --- Fuzzy Matching & Scoring ---

  double _matchScore(String query, String field1, [String? field2, String? field3, String? field4]) {
    final fields = [field1, field2, field3, field4].whereType<String>().map((f) => f.toLowerCase().trim()).toList();

    double bestScore = 0.0;
    for (final rawField in fields) {
      final normalizedField = rawField.startsWith('the ') ? rawField.substring(4) : rawField;
      final candidates = <String>{rawField, normalizedField, ...rawField.split(RegExp(r'[\s/,-]+'))};

      for (final f in candidates) {
        if (f.isEmpty) continue;
        if (f == query) return 1.0; // Exact match
        if (f.startsWith(query)) {
          bestScore = max(bestScore, 0.88);
        } else if (f.contains(query) || query.contains(f)) {
          bestScore = max(bestScore, 0.75);
        } else {
          // Levenshtein fuzzy distance
          final dist = _levenshteinDistance(query, f);
          final maxLen = max(query.length, f.length);
          if (maxLen > 0) {
            final similarity = 1.0 - (dist / maxLen);
            if (similarity >= 0.55) {
              bestScore = max(bestScore, similarity * 0.85);
            }
          }
        }
      }
    }
    return bestScore;
  }

  int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  String _detectCategory(String query, List<dynamic> songs, List<dynamic> artists, List<dynamic> albums) {
    final genres = {'synthwave', 'french house', 'nu-disco', 'dream pop', 'r&b', 'pop', 'indie', 'punjabi', 'hindi', 'electronic'};
    final moods = {'energetic', 'chill', 'late night', 'party', 'focus', 'relax', 'euphoric', 'peaceful'};

    if (genres.contains(query)) return 'genre';
    if (moods.contains(query)) return 'mood';
    if (artists.any((a) => a.name.toLowerCase() == query)) return 'artist';
    if (albums.any((a) => a.title.toLowerCase() == query)) return 'album';
    if (songs.any((s) => s.title.toLowerCase() == query)) return 'song';
    return 'all';
  }

  List<String> _generateSuggestions(String query, List<dynamic> songs, List<dynamic> artists, List<dynamic> albums) {
    final suggestions = <String>{};
    for (final a in artists) {
      if (a.name.toLowerCase().contains(query)) suggestions.add(a.name);
    }
    for (final s in songs) {
      if (s.title.toLowerCase().contains(query)) suggestions.add(s.title);
    }
    for (final al in albums) {
      if (al.title.toLowerCase().contains(query)) suggestions.add(al.title);
    }
    return suggestions.take(5).toList();
  }

  List<RecommendationItem> _getTopRecommendations(List<dynamic> songs, UserTasteProfile profile, {int limit = 6}) {
    final items = <RecommendationItem>[];
    for (final song in songs) {
      final score = profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: _extractGenre(song),
        mood: _extractMood(song),
        year: _extractYear(song),
      );
      items.add(RecommendationItem(
        song: song,
        score: score,
        explanation: 'Top pick tailored to your listening taste',
        source: RecommendationSource.tasteProfile,
      ));
    }
    items.sort((a, b) => b.score.compareTo(a.score));
    return items.take(limit).toList();
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

  String _extractMood(dynamic song) {
    try {
      return (song.mood as String?) ?? 'Energetic';
    } catch (_) {
      return 'Energetic';
    }
  }
}
