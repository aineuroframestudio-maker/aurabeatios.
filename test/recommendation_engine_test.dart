import 'package:flutter_test/flutter_test.dart';
import 'package:aurabeat/recommendations/recommendation_engine.dart';

// Test Mock Song Model
class TestSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final int durationSec;
  final String coverUrl;
  final String genre;
  final int year;
  final int bpm;
  final String mood;
  final String language;
  final int popularity;

  const TestSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.duration = '3:30',
    this.durationSec = 210,
    this.coverUrl = 'https://example.com/cover.jpg',
    required this.genre,
    required this.year,
    required this.bpm,
    required this.mood,
    this.language = 'English',
    this.popularity = 85,
  });
}

class TestArtist {
  final String id;
  final String name;
  final String genre;
  final String avatarUrl;
  final String monthlyListeners;

  const TestArtist({
    required this.id,
    required this.name,
    required this.genre,
    this.avatarUrl = 'https://example.com/artist.jpg',
    this.monthlyListeners = '20M',
  });
}

class TestAlbum {
  final String id;
  final String title;
  final String artist;
  final String year;
  final String coverUrl;
  final String genre;

  const TestAlbum({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    this.coverUrl = 'https://example.com/album.jpg',
    required this.genre,
  });
}

void main() {
  group('AuraBeat Recommendation Engine Tests', () {
    late List<TestSong> catalog;
    late List<TestArtist> artists;
    late List<TestAlbum> albums;
    late RecommendationEngine engine;

    setUp(() {
      engine = RecommendationEngine.instance;
      engine.resetTaste();

      catalog = const [
        TestSong(id: '1', title: 'Midnight City', artist: 'M83', album: 'Hurry Up, We\'re Dreaming', genre: 'Synthwave', year: 2011, bpm: 105, mood: 'Energetic'),
        TestSong(id: '2', title: 'Starboy', artist: 'The Weeknd ft. Daft Punk', album: 'Starboy', genre: 'R&B / Synthwave', year: 2016, bpm: 186, mood: 'Energetic'),
        TestSong(id: '3', title: 'Get Lucky', artist: 'Daft Punk', album: 'Random Access Memories', genre: 'Nu-Disco / French House', year: 2013, bpm: 116, mood: 'Party'),
        TestSong(id: '4', title: 'Blinding Lights', artist: 'The Weeknd', album: 'After Hours', genre: 'Synthwave', year: 2020, bpm: 171, mood: 'Energetic'),
        TestSong(id: '5', title: 'Instant Crush', artist: 'Daft Punk', album: 'Random Access Memories', genre: 'French House', year: 2013, bpm: 110, mood: 'Late Night'),
        TestSong(id: '6', title: 'The Less I Know The Better', artist: 'Tame Impala', album: 'Currents', genre: 'Psychedelic Pop', year: 2015, bpm: 117, mood: 'Chill'),
        TestSong(id: '7', title: 'Nightcall', artist: 'Kavinsky', album: 'OutRun', genre: 'Synthwave', year: 2013, bpm: 91, mood: 'Late Night'),
        TestSong(id: '8', title: 'Wait', artist: 'M83', album: 'Hurry Up, We\'re Dreaming', genre: 'Dream Pop', year: 2011, bpm: 128, mood: 'Chill'),
        TestSong(id: '9', title: 'One More Time', artist: 'Daft Punk', album: 'Discovery', genre: 'French House', year: 2001, bpm: 123, mood: 'Party'),
        TestSong(id: '10', title: 'Save Your Tears', artist: 'The Weeknd', album: 'After Hours', genre: 'Synthwave / R&B', year: 2020, bpm: 118, mood: 'Energetic'),
        TestSong(id: '11', title: 'Lover', artist: 'Diljit Dosanjh', album: 'MoonChild Era', genre: 'Punjabi Pop', year: 2021, bpm: 105, mood: 'Energetic', language: 'Punjabi'),
        TestSong(id: '12', title: '295', artist: 'Sidhu Moose Wala', album: 'Moosetape', genre: 'Punjabi Pop / Hip-Hop', year: 2021, bpm: 94, mood: 'Intense', language: 'Punjabi'),
      ];

      artists = const [
        TestArtist(id: 'ar1', name: 'The Weeknd', genre: 'R&B / Synthwave'),
        TestArtist(id: 'ar2', name: 'Daft Punk', genre: 'French House / Disco'),
        TestArtist(id: 'ar3', name: 'M83', genre: 'Dream Pop / Synthwave'),
        TestArtist(id: 'ar4', name: 'Tame Impala', genre: 'Psychedelic Pop'),
        TestArtist(id: 'ar5', name: 'Kavinsky', genre: 'Synthwave / OutRun'),
        TestArtist(id: 'ar6', name: 'Diljit Dosanjh', genre: 'Punjabi Pop'),
      ];

      albums = const [
        TestAlbum(id: 'al1', title: 'Hurry Up, We\'re Dreaming', artist: 'M83', year: '2011', genre: 'Synthwave / Dream Pop'),
        TestAlbum(id: 'al2', title: 'Random Access Memories', artist: 'Daft Punk', year: '2013', genre: 'Nu-Disco / French House'),
        TestAlbum(id: 'al3', title: 'After Hours', artist: 'The Weeknd', year: '2020', genre: 'Synthwave / R&B'),
      ];
    });

    test('1. UserTasteProfile records play and updates affinities', () {
      final song = catalog.first; // Midnight City (M83, Synthwave)
      final initialAffinity = engine.profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: song.genre,
      );

      // Record 100% completed play
      engine.recordPlay(song, 240, false);

      final updatedAffinity = engine.profile.computeSongAffinity(
        songId: song.id,
        artist: song.artist,
        genre: song.genre,
      );

      expect(updatedAffinity, greaterThan(initialAffinity));
      expect(engine.profile.history.length, 1);
      expect(engine.profile.history.first.songId, song.id);
    });

    test('2. TrackSimilarityService calculates high similarity for matching genre and artist', () {
      final song1 = catalog[0]; // Midnight City (M83, Synthwave)
      final song2 = catalog[6]; // Nightcall (Kavinsky, Synthwave)
      final song3 = catalog[10]; // Lover (Diljit Dosanjh, Punjabi Pop)

      final simElectronic = engine.trackSimilarity.computeSimilarity(song1, song2);
      final simCrossGenre = engine.trackSimilarity.computeSimilarity(song1, song3);

      expect(simElectronic, greaterThan(simCrossGenre));
      expect(simElectronic, greaterThan(0.50));
    });

    test('3. DailyMixService produces 6 distinct mixes with zero track overlap', () {
      final mixes = engine.getDailyMixes(catalog);

      expect(mixes.length, 6);
      expect(mixes[0].title, 'Daily Mix 1');
      expect(mixes[1].title, 'Daily Mix 2');
      expect(mixes[5].title, 'Daily Mix 6');

      // Verify ZERO track collisions across all 6 mixes
      final seenSongIds = <String>{};
      for (final mix in mixes) {
        expect(mix.tracks, isNotEmpty);
        for (final track in mix.tracks) {
          expect(seenSongIds.contains(track.id), isFalse,
              reason: 'Track ${track.id} (${track.title}) duplicated across Daily Mixes');
          seenSongIds.add(track.id);
        }
      }
    });

    test('4. DiscoverWeekly prioritizes unplayed tracks and applies novelty bonus', () {
      // Mark first 3 songs as heavily played
      for (int i = 0; i < 3; i++) {
        engine.recordPlay(catalog[i], 200, false);
      }

      final discoverWeekly = engine.getDiscoverWeekly(catalog);
      expect(discoverWeekly.tracks, isNotEmpty);
      expect(discoverWeekly.badge, 'DISCOVERY');
    });

    test('5. ReleaseRadar prioritizes recent releases', () {
      final radar = engine.getReleaseRadar(catalog);
      expect(radar.tracks, isNotEmpty);
      expect(radar.badge, 'NEW RELEASES');
      // 2020-2021 releases should be prominent
      final years = radar.tracks.map((s) => s.year as int).toList();
      expect(years.any((y) => y >= 2020), isTrue);
    });

    test('6. RadioGenerationService enforces artist diversity rule (<= 2 consecutive)', () {
      final radio = engine.createRadioForArtist('Daft Punk', catalog);
      expect(radio.queue, isNotEmpty);
      expect(radio.title, contains('Daft Punk Radio'));

      // Check artist diversity: never 3 consecutive tracks from the same artist
      for (int i = 2; i < radio.queue.length; i++) {
        final artist0 = radio.queue[i - 2].artist;
        final artist1 = radio.queue[i - 1].artist;
        final artist2 = radio.queue[i].artist;
        final allSame = (artist0 == artist1) && (artist1 == artist2);
        expect(allSame, isFalse, reason: 'Artist $artist2 repeated 3 times in a row in Radio station');
      }
    });

    test('7. AutoplayRecommendationService predicts relevant next track avoiding session history', () {
      final currentSong = catalog[0]; // Midnight City
      final sessionHistory = [catalog[0].id, catalog[1].id]; // Already played 1 & 2

      final nextTrack = engine.getNextAutoplayTrack(currentSong, catalog, sessionHistory);
      expect(nextTrack, isNotNull);
      expect(sessionHistory.contains(nextTrack.id), isFalse);
    });

    test('8. SearchRecommendationService handles fuzzy typo correction and suggestions', () {
      // Typo test: "weknd" -> should match "The Weeknd"
      final resultTypo = engine.search(
        query: 'weknd',
        songs: catalog,
        artists: artists,
        albums: albums,
      );

      expect(resultTypo.matchingArtists.isNotEmpty, isTrue);
      expect(resultTypo.matchingArtists.first.name, 'The Weeknd');

      // Exact song search
      final resultSong = engine.search(
        query: 'Midnight City',
        songs: catalog,
        artists: artists,
        albums: albums,
      );

      expect(resultSong.bestMatchSong, isNotNull);
      expect(resultSong.bestMatchSong.title, 'Midnight City');
      expect(resultSong.similarSongs, isNotEmpty);
    });

    test('9. RecommendationEngine respects hidden artists and hidden songs', () {
      engine.profile.hideArtist('Kavinsky');
      engine.profile.hideSong('4'); // Blinding Lights

      final similar = engine.getSimilarSongs(catalog[0], catalog);
      for (final item in similar) {
        expect(item.song.artist, isNot('Kavinsky'));
        expect(item.song.id, isNot('4'));
      }
    });
  });
}
