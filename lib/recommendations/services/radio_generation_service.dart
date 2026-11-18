import '../models/recommendation_models.dart';
import '../models/user_taste_profile.dart';
import 'track_similarity_service.dart';

/// Service synthesizing continuous, infinite-feel radio stations from any
/// song, artist, album, genre, or mood seed with strict artist diversity guards.
class RadioGenerationService {
  final TrackSimilarityService _trackSimilarity;

  const RadioGenerationService({
    TrackSimilarityService trackSimilarity = const TrackSimilarityService(),
  }) : _trackSimilarity = trackSimilarity;

  /// Creates a radio station seeded from a Song
  RadioStation createSongRadio({
    required dynamic seedSong,
    required List<dynamic> catalog,
    required UserTasteProfile profile,
    int initialTracks = 18,
  }) {
    final queue = <dynamic>[seedSong];
    final recentArtists = <String>[seedSong.artist.toLowerCase()];

    // Generate ranked candidates based on similarity to seed
    final similar = _trackSimilarity.getSimilarSongs(seedSong, catalog, limit: catalog.length, profile: profile);

    for (final rec in similar) {
      if (queue.length >= initialTracks) break;
      final candidate = rec.song;
      if (queue.any((s) => s.id == candidate.id)) continue;
      if (profile.hiddenSongIds.contains(candidate.id) ||
          profile.hiddenArtists.contains(candidate.artist)) {
        continue;
      }

      // Check artist diversity: avoid 3 consecutive tracks from the same artist
      final artistLower = candidate.artist.toLowerCase();
      if (recentArtists.length >= 2 &&
          recentArtists[recentArtists.length - 1] == artistLower &&
          recentArtists[recentArtists.length - 2] == artistLower) {
        continue; // Diversity penalty skip
      }

      queue.add(candidate);
      recentArtists.add(artistLower);
    }

    return RadioStation(
      id: 'radio_song_${seedSong.id}',
      title: '${seedSong.title} Radio',
      subtitle: 'Continuous station inspired by ${seedSong.artist}',
      coverUrl: seedSong.coverUrl,
      seedType: 'song',
      seedId: seedSong.id,
      queue: queue,
    );
  }

  /// Creates a radio station seeded from an Artist
  RadioStation createArtistRadio({
    required String artistName,
    required List<dynamic> catalog,
    required UserTasteProfile profile,
    int initialTracks = 18,
  }) {
    final lowerArtist = artistName.toLowerCase();
    final artistTracks = catalog.where((s) => s.artist.toLowerCase().contains(lowerArtist)).toList();
    dynamic seedSong = artistTracks.isNotEmpty ? artistTracks.first : catalog.first;

    final queue = <dynamic>[seedSong];
    final recentArtists = <String>[artistName.toLowerCase()];

    // Mix 40% other tracks from this artist + 60% tracks from similar artists
    final otherTracks = catalog.where((s) => s.id != seedSong.id).toList();
    otherTracks.sort((a, b) {
      double scoreA = _trackSimilarity.computeSimilarity(seedSong, a);
      double scoreB = _trackSimilarity.computeSimilarity(seedSong, b);
      if (a.artist.toLowerCase().contains(lowerArtist)) scoreA += 0.40;
      if (b.artist.toLowerCase().contains(lowerArtist)) scoreB += 0.40;
      return scoreB.compareTo(scoreA);
    });

    for (final candidate in otherTracks) {
      if (queue.length >= initialTracks) break;
      if (profile.hiddenSongIds.contains(candidate.id) ||
          profile.hiddenArtists.contains(candidate.artist)) {
        continue;
      }

      final artistLower = candidate.artist.toLowerCase();
      if (recentArtists.length >= 2 &&
          recentArtists[recentArtists.length - 1] == artistLower &&
          recentArtists[recentArtists.length - 2] == artistLower) {
        continue;
      }

      queue.add(candidate);
      recentArtists.add(artistLower);
    }

    return RadioStation(
      id: 'radio_artist_$artistName',
      title: '$artistName Radio',
      subtitle: 'Featuring $artistName and similar icons',
      coverUrl: seedSong.coverUrl,
      seedType: 'artist',
      seedId: artistName,
      queue: queue,
    );
  }

  /// Creates a radio station seeded from a Genre
  RadioStation createGenreRadio({
    required String genre,
    required List<dynamic> catalog,
    required UserTasteProfile profile,
    int initialTracks = 18,
  }) {
    final lowerGenre = genre.toLowerCase();
    final matching = catalog.where((s) {
      final g = _extractGenre(s).toLowerCase();
      return g.contains(lowerGenre);
    }).toList();

    matching.sort((a, b) {
      final affA = profile.computeSongAffinity(
        songId: a.id,
        artist: a.artist,
        genre: _extractGenre(a),
        mood: _extractMood(a),
        year: _extractYear(a),
      );
      final affB = profile.computeSongAffinity(
        songId: b.id,
        artist: b.artist,
        genre: _extractGenre(b),
        mood: _extractMood(b),
        year: _extractYear(b),
      );
      return affB.compareTo(affA);
    });

    final queue = matching.take(initialTracks).toList();
    final cover = queue.isNotEmpty ? queue.first.coverUrl : '';

    return RadioStation(
      id: 'radio_genre_$genre',
      title: '$genre Radio',
      subtitle: 'Pure $genre continuous sonic journey',
      coverUrl: cover,
      seedType: 'genre',
      seedId: genre,
      queue: queue,
    );
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
