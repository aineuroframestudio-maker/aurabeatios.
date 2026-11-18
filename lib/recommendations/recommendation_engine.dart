import 'models/recommendation_models.dart';
import 'models/user_taste_profile.dart';
import 'services/track_similarity_service.dart';
import 'services/artist_similarity_service.dart';
import 'services/album_recommendation_service.dart';
import 'services/search_recommendation_service.dart';
import 'services/daily_mix_service.dart';
import 'services/discovery_service.dart';
import 'services/release_recommendation_service.dart';
import 'services/radio_generation_service.dart';
import 'services/autoplay_recommendation_service.dart';
import 'services/recommendation_ranking_service.dart';
import 'cache/recommendation_cache.dart';

export 'models/recommendation_models.dart';
export 'models/user_taste_profile.dart';

/// Centralized Recommendation Engine for AuraBeat.
/// Unifies user taste profiling, track similarity, artist discovery, intelligent search,
/// Daily Mix synthesis, continuous radio generation, and queue autoplay.
class RecommendationEngine {
  static final RecommendationEngine instance = RecommendationEngine._internal();

  final UserTasteProfile profile;
  final TrackSimilarityService trackSimilarity;
  final ArtistSimilarityService artistSimilarity;
  final AlbumRecommendationService albumRecommendation;
  final SearchRecommendationService searchRecommendation;
  final DailyMixService dailyMix;
  final DiscoveryService discovery;
  final ReleaseRecommendationService releaseRecommendation;
  final RadioGenerationService radioGeneration;
  final AutoplayRecommendationService autoplayRecommendation;
  final RecommendationRankingService ranking;
  final RecommendationCache cache;

  RecommendationEngine._internal()
      : profile = UserTasteProfile(),
        trackSimilarity = const TrackSimilarityService(),
        artistSimilarity = const ArtistSimilarityService(),
        albumRecommendation = const AlbumRecommendationService(),
        searchRecommendation = const SearchRecommendationService(),
        dailyMix = const DailyMixService(),
        discovery = const DiscoveryService(),
        releaseRecommendation = const ReleaseRecommendationService(),
        radioGeneration = const RadioGenerationService(),
        autoplayRecommendation = const AutoplayRecommendationService(),
        ranking = const RecommendationRankingService(),
        cache = RecommendationCache();

  // --- Daily Mixes & Dynamic Playlists ---

  List<PersonalizedMix> getDailyMixes(List<dynamic> catalog) {
    const cacheKey = 'daily_mixes';
    final cached = cache.get<List<PersonalizedMix>>(cacheKey);
    if (cached != null) return cached;

    final mixes = dailyMix.generateDailyMixes(catalog: catalog, profile: profile);
    cache.set(cacheKey, mixes, ttl: const Duration(minutes: 15));
    return mixes;
  }

  PersonalizedMix getDiscoverWeekly(List<dynamic> catalog) {
    const cacheKey = 'discover_weekly';
    final cached = cache.get<PersonalizedMix>(cacheKey);
    if (cached != null) return cached;

    final mix = discovery.generateDiscoverWeekly(catalog: catalog, profile: profile);
    cache.set(cacheKey, mix, ttl: const Duration(minutes: 20));
    return mix;
  }

  PersonalizedMix getReleaseRadar(List<dynamic> catalog) {
    const cacheKey = 'release_radar';
    final cached = cache.get<PersonalizedMix>(cacheKey);
    if (cached != null) return cached;

    final mix = releaseRecommendation.generateReleaseRadar(catalog: catalog, profile: profile);
    cache.set(cacheKey, mix, ttl: const Duration(minutes: 20));
    return mix;
  }

  // --- Song & Artist Recommendations ---

  List<RecommendationItem> getSimilarSongs(dynamic seedSong, List<dynamic> catalog, {int limit = 8}) {
    final cacheKey = 'similar_songs_${seedSong.id}_$limit';
    final cached = cache.get<List<RecommendationItem>>(cacheKey);
    if (cached != null) return cached;

    final rawSimilar = trackSimilarity.getSimilarSongs(seedSong, catalog, limit: limit * 2, profile: profile);
    final ranked = ranking.rankAndDiversify(candidates: rawSimilar, profile: profile, limit: limit);

    cache.set(cacheKey, ranked, ttl: const Duration(minutes: 10));
    return ranked;
  }

  List<dynamic> getSimilarArtists(String artistName, List<dynamic> artists, {int limit = 5}) {
    return artistSimilarity.getSimilarArtists(artistName, artists, limit: limit, profile: profile);
  }

  List<dynamic> getSimilarAlbums(dynamic seedAlbum, List<dynamic> albums, {int limit = 4}) {
    return albumRecommendation.getSimilarAlbums(seedAlbum, albums, limit: limit);
  }

  List<RecommendationItem> getHiddenGems(List<dynamic> catalog, {int limit = 6}) {
    return discovery.getHiddenGems(catalog: catalog, profile: profile, limit: limit);
  }

  // --- Radio & Autoplay ---

  RadioStation createRadioForSong(dynamic song, List<dynamic> catalog) {
    return radioGeneration.createSongRadio(seedSong: song, catalog: catalog, profile: profile);
  }

  RadioStation createRadioForArtist(String artist, List<dynamic> catalog) {
    return radioGeneration.createArtistRadio(artistName: artist, catalog: catalog, profile: profile);
  }

  RadioStation createRadioForGenre(String genre, List<dynamic> catalog) {
    return radioGeneration.createGenreRadio(genre: genre, catalog: catalog, profile: profile);
  }

  dynamic getNextAutoplayTrack(
    dynamic currentSong,
    List<dynamic> catalog,
    List<String> sessionHistory,
  ) {
    return autoplayRecommendation.getNextAutoplayTrack(
      currentSong: currentSong,
      catalog: catalog,
      profile: profile,
      sessionPlayedSongIds: sessionHistory,
    );
  }

  // --- Intelligent Search ---

  SearchRecommendationResult search({
    required String query,
    required List<dynamic> songs,
    required List<dynamic> artists,
    required List<dynamic> albums,
  }) {
    return searchRecommendation.search(
      query: query,
      songs: songs,
      artists: artists,
      albums: albums,
      profile: profile,
    );
  }

  // --- Feedback & Event Tracking ---

  void recordPlay(dynamic song, double durationSec, bool skipped) {
    final completedFraction = song.durationSec > 0
        ? (durationSec / song.durationSec).clamp(0.0, 1.0)
        : 1.0;

    String genre = 'Electronic';
    String mood = 'Energetic';
    int year = 2018;
    String language = 'English';
    try {
      genre = (song.genre as String?) ?? 'Electronic';
      mood = (song.mood as String?) ?? 'Energetic';
      year = (song.year as int?) ?? 2018;
      language = (song.language as String?) ?? 'English';
    } catch (_) {}

    profile.recordPlay(
      songId: song.id,
      artist: song.artist,
      genre: genre,
      durationSeconds: durationSec,
      completedFraction: completedFraction,
      wasSkipped: skipped,
      mood: mood,
      year: year,
      language: language,
    );

    // Invalidate cached mixes so they can adapt to the updated taste vector
    cache.invalidate('daily_mixes');
    cache.invalidate('discover_weekly');
  }

  void recordLike(dynamic song, bool isLiked) {
    String genre = 'Electronic';
    try {
      genre = (song.genre as String?) ?? 'Electronic';
    } catch (_) {}

    profile.recordLike(song.id, song.artist, genre, isLiked);
    cache.invalidateAll();
  }

  void resetTaste() {
    profile.resetTaste();
    cache.invalidateAll();
  }
}
