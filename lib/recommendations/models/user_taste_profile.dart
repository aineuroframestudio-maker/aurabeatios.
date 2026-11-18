import 'recommendation_models.dart';

/// Centralized user preference model maintaining multi-dimensional taste vectors
/// with exponential recency decay, explicit likes, skips, and discovery behavior.
class UserTasteProfile {
  // Affinity Maps (normalized 0.0 to 1.0 or weighted positive)
  final Map<String, double> genreAffinities = {};
  final Map<String, double> artistAffinities = {};
  final Map<String, double> moodAffinities = {};
  final Map<String, double> eraAffinities = {};
  final Map<String, double> languageAffinities = {};

  // Explicit sets
  final Set<String> likedSongIds = {};
  final Set<String> followedArtists = {};
  final Set<String> savedAlbumIds = {};
  final Set<String> hiddenArtists = {};
  final Set<String> hiddenSongIds = {};

  // Discovery & History
  final List<String> recentSearches = [];
  final List<ListeningEvent> history = [];

  // Settings
  bool recommendationsEnabled = true;
  bool autoplayEnabled = true;
  bool searchPersonalizationEnabled = true;

  // Recency decay constants
  static const double lambdaHalfLife14Days = 0.0495; // ln(2) / 14 days

  UserTasteProfile() {
    _initDefaults();
  }

  void _initDefaults() {
    // Seed sensible initial baseline weights based on core catalog
    genreAffinities['Synthwave'] = 0.85;
    genreAffinities['French House'] = 0.80;
    genreAffinities['Dream Pop'] = 0.75;
    genreAffinities['Nu-Disco'] = 0.70;
    genreAffinities['R&B'] = 0.65;
    genreAffinities['Psychedelic Pop'] = 0.60;
    genreAffinities['Punjabi Pop'] = 0.55;
    genreAffinities['Hindi'] = 0.50;

    artistAffinities['Daft Punk'] = 0.90;
    artistAffinities['The Weeknd'] = 0.85;
    artistAffinities['M83'] = 0.80;
    artistAffinities['Tame Impala'] = 0.75;
    artistAffinities['Kavinsky'] = 0.70;

    moodAffinities['Energetic'] = 0.80;
    moodAffinities['Late Night'] = 0.85;
    moodAffinities['Chill'] = 0.75;
    moodAffinities['Euphoric'] = 0.70;

    eraAffinities['2010s'] = 0.80;
    eraAffinities['2020s'] = 0.85;
    eraAffinities['2000s'] = 0.70;

    likedSongIds.addAll({'1', '3'}); // Midnight City, Get Lucky
  }

  /// Record a song play with completion metrics and update taste vectors
  void recordPlay({
    required String songId,
    required String artist,
    required String genre,
    required double durationSeconds,
    required double completedFraction,
    required bool wasSkipped,
    String? mood,
    int? year,
    String? language,
  }) {
    final now = DateTime.now();
    final event = ListeningEvent(
      songId: songId,
      artist: artist,
      genre: genre,
      timestamp: now,
      durationSeconds: durationSeconds,
      completionRatio: completedFraction,
      wasSkipped: wasSkipped,
      wasLiked: likedSongIds.contains(songId),
    );

    history.add(event);
    if (history.length > 500) {
      history.removeAt(0);
    }

    if (!recommendationsEnabled) return;

    // Weight delta based on completion
    double weightDelta = 0.0;
    if (wasSkipped && completedFraction < 0.25) {
      weightDelta = -0.08; // Skip penalty
    } else if (completedFraction >= 0.80) {
      weightDelta = 0.15; // Completed play bonus
    } else {
      weightDelta = 0.06; // Partial listen
    }

    _updateAffinity(genreAffinities, genre, weightDelta);
    _updateAffinity(artistAffinities, artist, weightDelta);
    if (mood != null) _updateAffinity(moodAffinities, mood, weightDelta * 0.7);
    if (language != null) _updateAffinity(languageAffinities, language, weightDelta * 0.6);
    if (year != null) {
      final era = _getEraKey(year);
      _updateAffinity(eraAffinities, era, weightDelta * 0.5);
    }
  }

  /// Record like or unlike
  void recordLike(String songId, String artist, String genre, bool isLiked) {
    if (isLiked) {
      likedSongIds.add(songId);
      _updateAffinity(genreAffinities, genre, 0.25);
      _updateAffinity(artistAffinities, artist, 0.25);
    } else {
      likedSongIds.remove(songId);
      _updateAffinity(genreAffinities, genre, -0.10);
      _updateAffinity(artistAffinities, artist, -0.10);
    }
  }

  /// Record user search query and adapt preferences
  void recordSearch(String query, {String? matchedGenre, String? matchedArtist}) {
    if (!searchPersonalizationEnabled) return;

    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    recentSearches.remove(trimmed);
    recentSearches.insert(0, trimmed);
    if (recentSearches.length > 25) {
      recentSearches.removeLast();
    }

    // Boost taste affinities if the search matches music dimensions
    if (matchedGenre != null) {
      _updateAffinity(genreAffinities, matchedGenre, 0.12);
    }
    if (matchedArtist != null) {
      _updateAffinity(artistAffinities, matchedArtist, 0.15);
    }
  }

  void hideArtist(String artist) {
    hiddenArtists.add(artist);
    artistAffinities[artist] = 0.0;
  }

  void unhideArtist(String artist) {
    hiddenArtists.remove(artist);
  }

  void hideSong(String songId) {
    hiddenSongIds.add(songId);
  }

  void unhideSong(String songId) {
    hiddenSongIds.remove(songId);
  }

  void clearRecentSearches() {
    recentSearches.clear();
  }

  void clearHistory() {
    history.clear();
  }

  void resetTaste() {
    genreAffinities.clear();
    artistAffinities.clear();
    moodAffinities.clear();
    eraAffinities.clear();
    languageAffinities.clear();
    likedSongIds.clear();
    followedArtists.clear();
    savedAlbumIds.clear();
    hiddenArtists.clear();
    hiddenSongIds.clear();
    recentSearches.clear();
    history.clear();
    _initDefaults();
  }

  /// Get aggregated user affinity for a given song (0.0 to 1.0)
  double computeSongAffinity({
    required String songId,
    required String artist,
    required String genre,
    String? mood,
    int? year,
    String? language,
  }) {
    if (hiddenArtists.contains(artist) || hiddenSongIds.contains(songId)) {
      return 0.0;
    }

    double score = 0.0;

    // Explicit like bonus
    if (likedSongIds.contains(songId)) {
      score += 0.35;
    }

    // Artist affinity (weight 0.30)
    final artistScore = artistAffinities[artist] ?? 0.20;
    score += artistScore * 0.30;

    // Genre affinity (weight 0.25)
    final genreScore = genreAffinities[genre] ?? 0.20;
    score += genreScore * 0.25;

    // Mood affinity (weight 0.10)
    if (mood != null) {
      final moodScore = moodAffinities[mood] ?? 0.15;
      score += moodScore * 0.10;
    }

    // Language affinity (weight 0.10)
    if (language != null) {
      final langScore = languageAffinities[language] ?? 0.20;
      score += langScore * 0.10;
    }

    // Era affinity (weight 0.05)
    if (year != null) {
      final era = _getEraKey(year);
      final eraScore = eraAffinities[era] ?? 0.15;
      score += eraScore * 0.05;
    }

    // Replay behavior bonus
    final playCount = history.where((e) => e.songId == songId).length;
    if (playCount >= 3) {
      score += 0.10;
    }

    return score.clamp(0.0, 1.0);
  }

  void _updateAffinity(Map<String, double> map, String key, double delta) {
    final current = map[key] ?? 0.25;
    final updated = (current + delta).clamp(0.05, 1.0);
    map[key] = double.parse(updated.toStringAsFixed(3));
  }

  String _getEraKey(int year) {
    if (year >= 2020) return '2020s';
    if (year >= 2010) return '2010s';
    if (year >= 2000) return '2000s';
    if (year >= 1990) return '1990s';
    if (year >= 1980) return '1980s';
    return 'Classic';
  }
}
