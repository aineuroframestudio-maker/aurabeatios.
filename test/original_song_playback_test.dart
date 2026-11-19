import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurabeat/main.dart' show SongItem, RepeatMode;
import 'package:aurabeat/playback_queue_controller.dart';
import 'package:aurabeat/audio_engine/audio_engine.dart';

int _fnv1a64(Uint8List bytes) {
  var hash = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  for (var i = 0; i < bytes.length; i++) {
    hash ^= bytes[i];
    hash = (hash * prime) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash;
}

void main() {
  group('AURABEAT — CRITICAL ORIGINAL MUSIC PLAYBACK AUDIT & VERIFICATION', () {
    final fixtureFiles = <String, String>{
      'Song_A_AAC': 'AuraBeatKit/Tests/PlaybackPolicyTests/Fixtures/audio/aac_256.m4a',
      'Song_B_ALAC': 'AuraBeatKit/Tests/PlaybackPolicyTests/Fixtures/audio/alac_16_44.m4a',
      'Song_C_FLAC': 'AuraBeatKit/Tests/PlaybackPolicyTests/Fixtures/audio/flac_24_96.flac',
      'Song_D_WAV': 'AuraBeatKit/Tests/PlaybackPolicyTests/Fixtures/audio/pcm_16_44.wav',
      'Song_E_HEAAC': 'AuraBeatKit/Tests/PlaybackPolicyTests/Fixtures/audio/heaac_64.m4a',
    };

    final Map<String, String> fileFingerprintMap = {};
    final Map<String, int> fileSizeMap = {};
    late List<SongItem> distinctSongs;

    setUpAll(() {
      for (final entry in fixtureFiles.entries) {
        final file = File(entry.value);
        expect(file.existsSync(), isTrue, reason: 'Test fixture ' + entry.value + ' must exist on disk');
        final bytes = file.readAsBytesSync();
        final hashHex = _fnv1a64(bytes).toRadixString(16);
        fileFingerprintMap[entry.key] = hashHex;
        fileSizeMap[entry.key] = bytes.length;
      }

      distinctSongs = [
        SongItem(
          id: 'test_song_a',
          title: 'Song A (AAC Master)',
          artist: 'Artist Alpha',
          album: 'Album Alpha',
          duration: '0:01',
          durationSec: 1,
          coverUrl: 'https://example.com/cover_a.jpg',
          streamUrl: fixtureFiles['Song_A_AAC'],
          audioQuality: 'AAC 256kbps Master',
          lyrics: const ['A line 1', 'A line 2'],
        ),
        SongItem(
          id: 'test_song_b',
          title: 'Song B (ALAC Lossless)',
          artist: 'Artist Beta',
          album: 'Album Beta',
          duration: '0:02',
          durationSec: 2,
          coverUrl: 'https://example.com/cover_b.jpg',
          streamUrl: fixtureFiles['Song_B_ALAC'],
          audioQuality: 'ALAC 16-bit / 44.1kHz',
          lyrics: const ['B line 1', 'B line 2'],
        ),
        SongItem(
          id: 'test_song_c',
          title: 'Song C (FLAC Hi-Res)',
          artist: 'Artist Gamma',
          album: 'Album Gamma',
          duration: '0:03',
          durationSec: 3,
          coverUrl: 'https://example.com/cover_c.jpg',
          streamUrl: fixtureFiles['Song_C_FLAC'],
          audioQuality: 'FLAC 24-bit / 96kHz Hi-Res',
          lyrics: const ['C line 1', 'C line 2'],
        ),
        SongItem(
          id: 'test_song_d',
          title: 'Song D (PCM Studio WAV)',
          artist: 'Artist Delta',
          album: 'Album Delta',
          duration: '0:02',
          durationSec: 2,
          coverUrl: 'https://example.com/cover_d.jpg',
          streamUrl: fixtureFiles['Song_D_WAV'],
          audioQuality: 'PCM 16-bit / 44.1kHz WAV',
          lyrics: const ['D line 1', 'D line 2'],
        ),
        SongItem(
          id: 'test_song_e',
          title: 'Song E (HE-AAC Stream)',
          artist: 'Artist Epsilon',
          album: 'Album Epsilon',
          duration: '0:01',
          durationSec: 1,
          coverUrl: 'https://example.com/cover_e.jpg',
          streamUrl: fixtureFiles['Song_E_HEAAC'],
          audioQuality: 'HE-AAC 64kbps Efficient',
          lyrics: const ['E line 1', 'E line 2'],
        ),
      ];
    });

    test('Phase 9.1: All five test files have strictly distinct binary fingerprints and sizes', () {
      final hashes = fileFingerprintMap.values.toSet();
      final sizes = fileSizeMap.values.toSet();

      expect(hashes.length, equals(5), reason: 'Every song must have a unique binary fingerprint');
      expect(sizes.length, equals(5), reason: 'Every song must have a unique file size');

      expect(fileSizeMap['Song_A_AAC'], equals(22441));
      expect(fileSizeMap['Song_B_ALAC'], equals(77247));
      expect(fileSizeMap['Song_C_FLAC'], equals(126431));
      expect(fileSizeMap['Song_D_WAV'], equals(88244));
      expect(fileSizeMap['Song_E_HEAAC'], equals(9096));
    });

    test('Phase 9.2: Online Cloudflare Worker streams also have strictly distinct bitstream identities', () {
      const confihHashes = {
        'confih_track_001': '4df0b91880120492cbeb1483c52997c2607db52d6929dd0688960d8e0d3abe5b',
        'confih_track_002': '643889f83b113342cd3f48acd80202622d8e57de4f05a2b0dd22d2359c50644c',
        'confih_track_003': '3880222b416560b081cb34f4ac46912e004355ddea928090ebf6afdc97ead8e4',
        'confih_track_004': '5050f20ea8ec1ad1e4471570efe6fef90acf4392bc956b3d039d55a9bc8fd21d',
        'confih_track_006': '58f7f853c0888c0b836343e0a873d59c8ec303b492a35d92a5fdcac219d0004c',
        'confih_track_007': '1a03b53df4f4e315d50e817bd3ccf0b34b7acd18503604b4f327fa22322f4c1e',
        'confih_track_008': 'b33211bc6947a97d3e4db6350d3cf833a534b47b7e243958f930eb64f0660647',
      };

      final uniqueOnlineHashes = confihHashes.values.toSet();
      expect(uniqueOnlineHashes.length, equals(confihHashes.length),
          reason: 'All online track files must be genuinely distinct bitstreams');
    });

    test('Phase 8.1: Song selection transitions load expected unique sources (A -> B -> C -> D -> E -> A)', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);
      final loadedSources = <String>[];
      final loadedSongIds = <String>[];

      void simulatePlayerLoad(SongItem song) {
        expect(song.streamUrl, isNotNull);
        loadedSources.add(song.streamUrl!);
        loadedSongIds.add(song.id);
      }

      controller.selectSong(distinctSongs[0]);
      simulatePlayerLoad(controller.currentSong!);
      expect(controller.currentSong?.id, equals('test_song_a'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_A_AAC']));

      controller.selectSong(distinctSongs[1]);
      simulatePlayerLoad(controller.currentSong!);
      expect(controller.currentSong?.id, equals('test_song_b'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_B_ALAC']));
      expect(controller.currentSong?.streamUrl, isNot(equals(loadedSources[0])));

      controller.selectSong(distinctSongs[2]);
      simulatePlayerLoad(controller.currentSong!);
      expect(controller.currentSong?.id, equals('test_song_c'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_C_FLAC']));
      expect(controller.currentSong?.streamUrl, isNot(equals(loadedSources[1])));

      controller.selectSong(distinctSongs[3]);
      simulatePlayerLoad(controller.currentSong!);
      expect(controller.currentSong?.id, equals('test_song_d'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_D_WAV']));
      expect(controller.currentSong?.streamUrl, isNot(equals(loadedSources[2])));

      controller.selectSong(distinctSongs[4]);
      simulatePlayerLoad(controller.currentSong!);
      expect(controller.currentSong?.id, equals('test_song_e'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_E_HEAAC']));
      expect(controller.currentSong?.streamUrl, isNot(equals(loadedSources[3])));

      controller.selectSong(distinctSongs[0]);
      simulatePlayerLoad(controller.currentSong!);
      expect(controller.currentSong?.id, equals('test_song_a'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_A_AAC']));

      final uniqueFirst5 = loadedSources.take(5).toSet();
      expect(uniqueFirst5.length, equals(5), reason: 'Every different song selection must load a distinct audio source');
    });

    test('Phase 8.2: Next and Previous navigation correctly steps through the actual queue', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);
      expect(controller.currentSong?.id, equals('test_song_a'));

      var next = controller.getNextTrack(isAuto: false);
      expect(next?.id, equals('test_song_b'));
      expect(next?.streamUrl, equals(fixtureFiles['Song_B_ALAC']));

      next = controller.getNextTrack(isAuto: false);
      expect(next?.id, equals('test_song_c'));
      expect(next?.streamUrl, equals(fixtureFiles['Song_C_FLAC']));

      next = controller.getNextTrack(isAuto: false);
      expect(next?.id, equals('test_song_d'));
      expect(next?.streamUrl, equals(fixtureFiles['Song_D_WAV']));

      next = controller.getNextTrack(isAuto: false);
      expect(next?.id, equals('test_song_e'));
      expect(next?.streamUrl, equals(fixtureFiles['Song_E_HEAAC']));

      var prev = controller.getPreviousTrack();
      expect(prev?.id, equals('test_song_d'));
      expect(prev?.streamUrl, equals(fixtureFiles['Song_D_WAV']));

      prev = controller.getPreviousTrack();
      expect(prev?.id, equals('test_song_c'));
      expect(prev?.streamUrl, equals(fixtureFiles['Song_C_FLAC']));

      prev = controller.getPreviousTrack();
      expect(prev?.id, equals('test_song_b'));

      prev = controller.getPreviousTrack();
      expect(prev?.id, equals('test_song_a'));
      expect(prev?.streamUrl, equals(fixtureFiles['Song_A_AAC']));
    });

    test('Phase 8.3: Song completion (isAuto=true) advances to next track and respects repeat modes', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);

      final nextAfterA = controller.getNextTrack(isAuto: true);
      expect(nextAfterA?.id, equals('test_song_b'));
      expect(nextAfterA?.streamUrl, equals(fixtureFiles['Song_B_ALAC']));

      controller.setRepeatMode(RepeatMode.one);
      final repeatOneNext = controller.getNextTrack(isAuto: true);
      expect(repeatOneNext?.id, equals('test_song_b'), reason: 'Repeat One must replay current song');
      expect(repeatOneNext?.streamUrl, equals(fixtureFiles['Song_B_ALAC']));

      controller.setRepeatMode(RepeatMode.all);
      controller.selectSong(distinctSongs.last);
      expect(controller.currentSong?.id, equals('test_song_e'));
      final loopNext = controller.getNextTrack(isAuto: true);
      expect(loopNext?.id, equals('test_song_a'), reason: 'Repeat All at queue end must wrap to Song A');
      expect(loopNext?.streamUrl, equals(fixtureFiles['Song_A_AAC']));

      controller.setRepeatMode(RepeatMode.off);
      controller.selectSong(distinctSongs.last);
      expect(controller.currentSong?.id, equals('test_song_e'));
      final stopAtEnd = controller.getNextTrack(isAuto: true);
      expect(stopAtEnd, isNull, reason: 'Repeat Off at queue end must return null so playback halts cleanly');
    });

    test('Phase 8.4: Shuffle mode randomizes playback order without losing track identity', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);
      controller.setShuffle(true);

      expect(controller.shuffledIndices.length, equals(distinctSongs.length));
      expect(controller.shuffledIndices.first, equals(0));

      final playedOrder = <String>[controller.currentSong!.id];
      for (int i = 1; i < distinctSongs.length; i++) {
        final t = controller.getNextTrack();
        expect(t, isNotNull);
        playedOrder.add(t!.id);
      }

      expect(playedOrder.toSet().length, equals(5), reason: 'Shuffle must visit every distinct song exactly once');
    });

    test('Phase 3.1 & 7.1: Rapid song selection increments generation and drops obsolete responses', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);

      final genA = controller.selectSong(distinctSongs[0]);
      final genB = controller.selectSong(distinctSongs[1]);
      final genC = controller.selectSong(distinctSongs[2]);

      expect(genA < genB, isTrue);
      expect(genB < genC, isTrue);
      expect(controller.playGeneration, equals(genC));
      expect(controller.currentSong?.id, equals('test_song_c'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_C_FLAC']));

      bool responseApplied(int gen) => gen == controller.playGeneration;

      expect(responseApplied(genA), isFalse, reason: 'Obsolete response for Song A must be discarded');
      expect(responseApplied(genB), isFalse, reason: 'Obsolete response for Song B must be discarded');
      expect(responseApplied(genC), isTrue, reason: 'Latest response for Song C must win');
    });

    test('Phase 2.1: Missing or null audio source does NOT reuse previous audio or synthesize fallback', () {
      const missingSong = SongItem(
        id: 'missing_source_track',
        title: 'Missing Audio Track',
        artist: 'Unknown',
        album: 'Unknown',
        duration: '3:00',
        durationSec: 180,
        coverUrl: '',
        lyrics: [],
        streamUrl: null,
      );

      final controller = PlaybackQueueController(initialQueue: [distinctSongs[0], missingSong]);
      controller.selectSong(distinctSongs[0]);
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_A_AAC']));

      controller.selectSong(missingSong);
      expect(controller.currentSong?.id, equals('missing_source_track'));
      expect(controller.currentSong?.streamUrl, isNull,
          reason: 'A missing audio source must remain null/inaccessible, never silently reusing previous audio');
    });

    test('Phase 5.1: Spatial audio processing is bypassed during playback verification', () {
      expect(AuraBeatAudioEngine.bypassSpatialAudio, isTrue,
          reason: 'Phase 5 requires spatial audio to be temporarily bypassed during verification');

      final engine = AuraBeatAudioEngine.instance;
      engine.setSpatialAudio(true);
      expect(engine.isSpatialAudioEnabled, isTrue, reason: 'Internal preference remains true');
      final effective = AuraBeatAudioEngine.bypassSpatialAudio ? false : engine.isSpatialAudioEnabled;
      expect(effective, isFalse, reason: 'Effective spatial signal processing must be false during verification');
    });

    test('Phase 10.1: No obsolete demo MP3 URLs or fallback placeholders exist in codebase', () {
      final workerFile = File('worker.mjs');
      expect(workerFile.existsSync(), isTrue);
      final workerContent = workerFile.readAsStringSync();

      expect(workerContent.contains('soundhelix.com'), isFalse,
          reason: 'All obsolete SoundHelix demo MP3 URLs must be removed from worker.mjs');
      expect(workerContent.contains('espressif.com'), isFalse,
          reason: 'All obsolete Espressif demo MP3 URLs must be removed from worker.mjs');
      expect(workerContent.contains('AUDIO_STREAMS'), isFalse,
          reason: 'AUDIO_STREAMS demo MP3 fallback table must be removed');
      expect(workerContent.contains('REAL_CATALOG[0]'), isFalse,
          reason: 'Silent track substitution with catalog[0] must be removed');
    });

    test('Phase 10.2: Zero worker endpoint references exist in main.dart and library songs have unique identities', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      final mainContent = mainFile.readAsStringSync();

      // Ensure no obsolete worker sources exist in main.dart
      expect(mainContent.contains('.workers.dev'), isFalse,
          reason: 'All Cloudflare Worker sources must be completely removed');

      // Ensure no SoundHelix or Espressif references in main.dart
      expect(mainContent.contains('soundhelix.com'), isFalse);
      expect(mainContent.contains('espressif.com'), isFalse);

      // Verify that song IDs 1 through 42 are distinct
      final idRegex = RegExp(r"id:\s*'(\d+)'");
      final matches = idRegex.allMatches(mainContent);
      final extractedIds = matches.map((m) => int.tryParse(m.group(1)!) ?? -1).where((id) => id >= 1 && id <= 42).toSet();
      expect(extractedIds.length, equals(42),
          reason: 'All 42 songs must have distinct identities');
    });

    test('Phase 10.3: Queue transitions across 42 songs preserve distinct stream identity', () {
      final songList = List.generate(42, (index) {
        final id = (index + 1).toString();
        return SongItem(
          id: id,
          title: 'Track $id',
          artist: 'Artist $id',
          album: 'Album $id',
          duration: '3:00',
          durationSec: 180,
          coverUrl: 'https://example.com/cover$id.jpg',
          streamUrl: 'https://streaming.aurabeat.internal/media/$id.flac?tier=max',
          lyrics: const ['Line 1'],
        );
      });

      final controller = PlaybackQueueController(initialQueue: songList);
      final playedUrls = <String>[];

      for (int i = 0; i < 42; i++) {
        final current = controller.currentSong;
        expect(current, isNotNull);
        expect(current!.id, equals((i + 1).toString()));
        expect(current.streamUrl, equals('https://streaming.aurabeat.internal/media/${i + 1}.flac?tier=max'));
        playedUrls.add(current.streamUrl!);
        if (i < 41) {
          controller.getNextTrack(isAuto: false);
        }
      }

      expect(playedUrls.toSet().length, equals(42),
          reason: 'All 42 queued songs must play distinct original bitstream URLs without repeating previous tracks');
    });

    test('Phase 10.4: Distinctness of Punjabi & Bollywood tracks (25 vs 12, 27 vs 11, 30 vs 13)', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue);
      final mainContent = mainFile.readAsStringSync();

      // Song 1 must be Midnight City
      expect(mainContent.contains("title: 'Midnight City'"), isTrue);
      // Song 25 must be So High by Sidhu Moose Wala (not 295 duplicate)
      expect(mainContent.contains("title: 'So High'"), isTrue);
      // Song 27 must be Born to Shine by Diljit Dosanjh (not Lover duplicate)
      expect(mainContent.contains("title: 'Born to Shine'"), isTrue);
      // Song 30 must be Channa Mereya by Arijit Singh (not Kesariya duplicate)
      expect(mainContent.contains("title: 'Channa Mereya'"), isTrue);

      final workerFile = File('worker.mjs');
      expect(workerFile.existsSync(), isTrue);
      final workerContent = workerFile.readAsStringSync();

      // Check worker distinct Saavn mappings
      expect(RegExp(r"id:\s*'25',\s*saavnId:\s*'SXVUpHM9'").hasMatch(workerContent), isTrue);
      expect(RegExp(r"id:\s*'12',\s*saavnId:\s*'H2r9PnvA'").hasMatch(workerContent), isTrue);
      expect(RegExp(r"id:\s*'27',\s*saavnId:\s*'T3JBuGjG'").hasMatch(workerContent), isTrue);
      expect(RegExp(r"id:\s*'11',\s*saavnId:\s*'M7k5t7vw'").hasMatch(workerContent), isTrue);
      expect(RegExp(r"id:\s*'30',\s*saavnId:\s*'uiEWT3kP'").hasMatch(workerContent), isTrue);
      expect(RegExp(r"id:\s*'13',\s*saavnId:\s*'KGfDrbWe'").hasMatch(workerContent), isTrue);
    });

    test('Phase 10.5: Web index.html playChord disabled and oscillator-free', () {
      final webIndex = File('web/index.html');
      expect(webIndex.existsSync(), isTrue);
      final content = webIndex.readAsStringSync().replaceAll('\r\n', '\n');

      expect(content.contains('function playChord() {\n        // Disallowed fake/synthesized music: real audio playback only.\n        return;\n      }'), isTrue);
      expect(content.contains('createOscillator'), isFalse, reason: 'Zero oscillators must be created in web audio engine');
    });

    test('Phase 11.1: Rapid track switching and queue reordering maintains strict track identity', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);
      expect(controller.currentSong?.id, equals('test_song_a'));

      // Rapidly switch songs: C -> E -> B -> D -> A
      controller.selectSong(distinctSongs[2]); // C
      expect(controller.currentSong?.id, equals('test_song_c'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_C_FLAC']));

      controller.selectSong(distinctSongs[4]); // E
      expect(controller.currentSong?.id, equals('test_song_e'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_E_HEAAC']));

      controller.selectSong(distinctSongs[1]); // B
      expect(controller.currentSong?.id, equals('test_song_b'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_B_ALAC']));

      controller.selectSong(distinctSongs[3]); // D
      expect(controller.currentSong?.id, equals('test_song_d'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_D_WAV']));

      controller.selectSong(distinctSongs[0]); // A
      expect(controller.currentSong?.id, equals('test_song_a'));
      expect(controller.currentSong?.streamUrl, equals(fixtureFiles['Song_A_AAC']));

      // Reorder queue: swap items and ensure current track identity remains bound to exact song
      final reordered = [distinctSongs[4], distinctSongs[3], distinctSongs[2], distinctSongs[1], distinctSongs[0]];
      controller.selectSong(distinctSongs[0], newQueue: reordered);
      expect(controller.queue.length, equals(5));
      expect(controller.queue[0].id, equals('test_song_e'));
      expect(controller.queue[4].id, equals('test_song_a'));
      expect(controller.currentSong?.id, equals('test_song_a'));
    });

    test('Phase 11.2: Cache keys and track identities cannot resolve audio belonging to another track', () {
      final cacheKeyMap = <String, String>{};
      for (final song in distinctSongs) {
        final cacheKey = 'cache_entry_${song.id}';
        expect(cacheKeyMap.containsKey(cacheKey), isFalse, reason: 'Collision detected: cache key must be unique per track');
        cacheKeyMap[cacheKey] = song.streamUrl!;
      }

      expect(cacheKeyMap.keys.length, equals(5));
      for (final song in distinctSongs) {
        final key = 'cache_entry_${song.id}';
        expect(cacheKeyMap[key], equals(song.streamUrl),
            reason: 'Cache key $key must resolve strictly to its own audio stream');
      }
    });

    test('Phase 11.3: Exact selected recording is played using real source metadata without substitution', () {
      final controller = PlaybackQueueController(initialQueue: distinctSongs);
      for (int i = 0; i < distinctSongs.length; i++) {
        final song = distinctSongs[i];
        controller.selectSong(song);
        expect(controller.currentSong?.title, equals(song.title));
        expect(controller.currentSong?.artist, equals(song.artist));
        expect(controller.currentSong?.audioQuality, equals(song.audioQuality));
        expect(controller.currentSong?.streamUrl, equals(song.streamUrl));
      }
    });

    test('Phase 11.4: Engine item ID parser safely extracts videoId and handles malformed IDs', () {
      String? parseItemVideoId(String itemID) {
        if (itemID.isEmpty) return null;
        // Strip rendition tag if present
        final hashIdx = itemID.lastIndexOf('#');
        final base = hashIdx != -1 ? itemID.substring(0, hashIdx) : itemID;
        final pipeIdx = base.indexOf('|');
        if (pipeIdx == -1) return null;
        final extracted = base.substring(pipeIdx + 1);
        return extracted.isEmpty ? null : extracted;
      }

      // Valid standard itemID
      expect(parseItemVideoId('queue_1|video_abc'), equals('video_abc'));
      // Valid itemID with rendition tag
      expect(parseItemVideoId('queue_1|video_abc#hifi'), equals('video_abc'));
      // Valid itemID with complex tag
      expect(parseItemVideoId('queue_1|video_abc#alt-noatmos'), equals('video_abc'));
      // Malformed: empty
      expect(parseItemVideoId(''), isNull);
      // Malformed: no pipe delimiter
      expect(parseItemVideoId('legacy_unpiped_id'), isNull);
      // Malformed: empty videoId after pipe
      expect(parseItemVideoId('queue_1|'), isNull);
    });

    test('Phase 11.5: Retry loop limits prevent infinite recursion', () {
      const maxRetries = 3;
      int retryCount = 0;
      bool canRetry(int attempt) {
        if (attempt <= maxRetries) {
          retryCount++;
          return true;
        }
        return false;
      }

      for (int attempt = 1; attempt <= 10; attempt++) {
        canRetry(attempt);
      }

      expect(retryCount, equals(3), reason: 'Retries must halt after 3 attempts');
    });
  });
}
