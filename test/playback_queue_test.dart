import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurabeat/main.dart' show SongItem, RepeatMode;
import 'package:aurabeat/playback_queue_controller.dart';

void main() {
  group('SongItem Equality & Identity Fix', () {
    test('SongItem equality is based on id, fixing indexOf lookup after copyWith', () {
      const songA = SongItem(
        id: 'track_001',
        title: 'Song One',
        artist: 'Artist A',
        album: 'Album 1',
        duration: '3:30',
        durationSec: 210,
        coverUrl: 'https://example.com/cover1.jpg',
        lyrics: [],
      );

      final clonedSongA = songA.copyWith(streamUrl: 'https://example.com/stream1.m3u8');

      expect(songA == clonedSongA, isTrue, reason: 'copyWith must preserve equality based on id');
      expect(songA.hashCode, equals(clonedSongA.hashCode));

      final songList = [songA];
      final foundIndex = songList.indexOf(clonedSongA);
      expect(foundIndex, equals(0), reason: 'songList.indexOf(clonedSong) must not return -1');
    });

    test('Different song ids evaluate to not equal', () {
      const song1 = SongItem(
        id: 'track_1',
        title: 'Track 1',
        artist: 'Artist',
        album: 'Album',
        duration: '3:00',
        durationSec: 180,
        coverUrl: '',
        lyrics: [],
      );
      const song2 = SongItem(
        id: 'track_2',
        title: 'Track 2',
        artist: 'Artist',
        album: 'Album',
        duration: '3:00',
        durationSec: 180,
        coverUrl: '',
        lyrics: [],
      );

      expect(song1 == song2, isFalse);
    });
  });

  group('PlaybackQueueController - Authoritative Queue & Selection', () {
    late List<SongItem> testSongs;
    late PlaybackQueueController controller;

    setUp(() {
      testSongs = List.generate(
        5,
        (i) => SongItem(
          id: 'song_$i',
          title: 'Track $i',
          artist: 'Artist $i',
          album: 'Album $i',
          duration: '3:00',
          durationSec: 180,
          coverUrl: 'https://example.com/cover$i.jpg',
          lyrics: const [],
        ),
      );
      controller = PlaybackQueueController(initialQueue: testSongs);
    });

    test('Initial state initializes with first song and index 0', () {
      expect(controller.queue.length, equals(5));
      expect(controller.queueIndex, equals(0));
      expect(controller.currentSong?.id, equals('song_0'));
    });

    test('Selecting another song updates currentSong and queueIndex correctly', () {
      final gen = controller.selectSong(testSongs[3]);
      expect(controller.currentSong?.id, equals('song_3'));
      expect(controller.queueIndex, equals(3));
      expect(gen, equals(1));
    });

    test('Selecting a new song with a new queue replaces the queue', () {
      final newQueue = [
        testSongs[2],
        testSongs[4],
      ];
      controller.selectSong(testSongs[4], newQueue: newQueue);
      expect(controller.queue.length, equals(2));
      expect(controller.queueIndex, equals(1));
      expect(controller.currentSong?.id, equals('song_4'));
    });

    test('Sequential next track advances through queue and stops at end with Repeat Off', () {
      expect(controller.repeatMode, equals(RepeatMode.off));

      final t1 = controller.getNextTrack();
      expect(t1?.id, equals('song_1'));
      expect(controller.queueIndex, equals(1));

      final t2 = controller.getNextTrack();
      expect(t2?.id, equals('song_2'));
      expect(controller.queueIndex, equals(2));

      final t3 = controller.getNextTrack();
      expect(t3?.id, equals('song_3'));

      final t4 = controller.getNextTrack();
      expect(t4?.id, equals('song_4'));
      expect(controller.queueIndex, equals(4));

      // End of queue with repeat off
      final tEnd = controller.getNextTrack();
      expect(tEnd, isNull, reason: 'Next track at end of queue with Repeat Off must be null');
      expect(controller.queueIndex, equals(4));
    });

    test('Previous track steps backward and clamps to 0 with Repeat Off', () {
      controller.selectSong(testSongs[2]);
      expect(controller.queueIndex, equals(2));

      final p1 = controller.getPreviousTrack();
      expect(p1?.id, equals('song_1'));
      expect(controller.queueIndex, equals(1));

      final p0 = controller.getPreviousTrack();
      expect(p0?.id, equals('song_0'));
      expect(controller.queueIndex, equals(0));

      final pClamp = controller.getPreviousTrack();
      expect(pClamp?.id, equals('song_0'));
      expect(controller.queueIndex, equals(0));
    });

    test('Repeat All loops to beginning on queue end', () {
      controller.setRepeatMode(RepeatMode.all);
      controller.selectSong(testSongs[4]);
      expect(controller.queueIndex, equals(4));

      final next = controller.getNextTrack();
      expect(next?.id, equals('song_0'), reason: 'Repeat All must wrap around to index 0');
      expect(controller.queueIndex, equals(0));
    });

    test('Repeat All wraps previous from 0 to last track', () {
      controller.setRepeatMode(RepeatMode.all);
      expect(controller.queueIndex, equals(0));

      final prev = controller.getPreviousTrack();
      expect(prev?.id, equals('song_4'), reason: 'Previous from 0 in Repeat All wraps to end');
      expect(controller.queueIndex, equals(4));
    });

    test('Repeat One replays the same track on automatic completion', () {
      controller.setRepeatMode(RepeatMode.one);
      controller.selectSong(testSongs[2]);

      final nextAuto = controller.getNextTrack(isAuto: true);
      expect(nextAuto?.id, equals('song_2'), reason: 'Automatic completion in Repeat One replays current song');
      expect(controller.queueIndex, equals(2));
    });

    test('Repeat One does not prevent manual next track', () {
      controller.setRepeatMode(RepeatMode.one);
      controller.selectSong(testSongs[2]);

      final nextManual = controller.getNextTrack(isAuto: false);
      expect(nextManual?.id, equals('song_3'), reason: 'Manual next track still advances in Repeat One');
      expect(controller.queueIndex, equals(3));
    });

    test('Shuffle mode randomizes ordering and visits all tracks', () {
      controller.setShuffle(true);
      expect(controller.isShuffle, isTrue);
      expect(controller.shuffledIndices.length, equals(5));
      expect(controller.shuffledIndices.first, equals(0), reason: 'First shuffled index should be current song');

      final visited = <String>{controller.currentSong!.id};
      for (int i = 0; i < 4; i++) {
        final next = controller.getNextTrack();
        expect(next, isNotNull);
        visited.add(next!.id);
      }

      expect(visited.length, equals(5), reason: 'All 5 distinct tracks must be played in shuffle mode');
    });

    test('Toggling repeat mode cycles off -> all -> one -> off', () {
      expect(controller.repeatMode, equals(RepeatMode.off));
      controller.toggleRepeat();
      expect(controller.repeatMode, equals(RepeatMode.all));
      controller.toggleRepeat();
      expect(controller.repeatMode, equals(RepeatMode.one));
      controller.toggleRepeat();
      expect(controller.repeatMode, equals(RepeatMode.off));
    });

    test('Rapid consecutive track selections increment play generation for race prevention', () {
      final gen1 = controller.selectSong(testSongs[0]);
      final gen2 = controller.selectSong(testSongs[1]);
      final gen3 = controller.selectSong(testSongs[2]);

      expect(gen1 < gen2, isTrue);
      expect(gen2 < gen3, isTrue);
      expect(controller.playGeneration, equals(gen3));
      expect(controller.currentSong?.id, equals('song_2'));
    });
  });
}
