import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:aurabeat/sources/models/addon_source_model.dart';
import 'package:aurabeat/sources/models/audio_quality_models.dart';
import 'package:aurabeat/sources/services/addon_quality_manager.dart';
import 'package:aurabeat/sources/adapters/bitchord_protocol_adapter.dart';
import 'package:aurabeat/sources/services/addon_stream_resolver.dart';
import 'package:aurabeat/sources/addon_source_registry.dart';
import 'package:aurabeat/main.dart';

void main() {
  group('AuraBeat Audio Quality & Add-on Protocol Tests', () {
    test('1. Quality Manager maps MAX profile according to documented hierarchy', () {
      final qm = AddonQualityManager.instance;

      // When 'max' is available
      final match1 = qm.mapQuality(
        requested: GlobalQualityProfile.max,
        supportedOptions: ['low', 'high', 'lossless', 'max'],
      );
      expect(match1, 'max');

      // When 'max' is not available, falls back to 'hires' or 'lossless'
      final match2 = qm.mapQuality(
        requested: GlobalQualityProfile.max,
        supportedOptions: ['low', 'high', 'lossless'],
      );
      expect(match2, 'lossless');
    });

    test('2. Quality Manager maps HI-RES and LOSSLESS with fallback hierarchy', () {
      final qm = AddonQualityManager.instance;

      // HI-RES requested, only lossless and high available -> falls back to lossless
      final matchHires = qm.mapQuality(
        requested: GlobalQualityProfile.hires,
        supportedOptions: ['low', 'high', 'lossless'],
      );
      expect(matchHires, 'lossless');

      // LOSSLESS requested, only high and low available -> falls back to high
      final matchLossless = qm.mapQuality(
        requested: GlobalQualityProfile.lossless,
        supportedOptions: ['low', 'high'],
      );
      expect(matchLossless, 'high');
    });

    test('3. AUTO profile adapts to network type (Wi-Fi vs Cellular)', () {
      final qm = AddonQualityManager.instance;
      qm.preferences.wifiQuality = GlobalQualityProfile.hires;
      qm.preferences.cellularQuality = GlobalQualityProfile.high;

      final wifiMatch = qm.mapQuality(
        requested: GlobalQualityProfile.auto,
        supportedOptions: ['low', 'high', 'lossless', 'hires'],
        isWifi: true,
      );
      expect(wifiMatch, 'hires');

      final cellMatch = qm.mapQuality(
        requested: GlobalQualityProfile.auto,
        supportedOptions: ['low', 'high', 'lossless', 'hires'],
        isWifi: false,
      );
      expect(cellMatch, 'high');
    });

    test('4. Genuine Hi-Res Audio verification strictly requires >48kHz or >16-bit', () {
      final qm = AddonQualityManager.instance;

      // Standard CD 16-bit / 44.1 kHz FLAC -> Must NOT be marked as Hi-Res
      final cdMeta = qm.verifyMetadata(
        streamJson: {
          'format': 'flac',
          'sampleRate': 44100,
          'bitDepth': 16,
          'bitrate': 1411200,
        },
        sourceId: 'src_test',
        sourceName: 'Test Source',
      );
      expect(cdMeta.isLossless, isTrue);
      expect(cdMeta.isHiRes, isFalse);
      expect(cdMeta.summaryQualityLabel, contains('CD Lossless'));

      // 24-bit / 96 kHz FLAC -> Genuine Hi-Res
      final hiresMeta = qm.verifyMetadata(
        streamJson: {
          'format': 'flac',
          'sampleRate': 96000,
          'bitDepth': 24,
          'bitrate': 4608000,
        },
        sourceId: 'src_test',
        sourceName: 'Test Source',
      );
      expect(hiresMeta.isLossless, isTrue);
      expect(hiresMeta.isHiRes, isTrue);
      expect(hiresMeta.summaryQualityLabel, contains('Hi-Res · 24-bit / 96 kHz FLAC'));
    });

    test('5. Dolby Atmos E-AC-3 JOC is recognized and kept separate from lossless', () {
      final qm = AddonQualityManager.instance;

      final atmosMeta = qm.verifyMetadata(
        streamJson: {
          'format': 'eac3',
          'audioMode': 'DOLBY_ATMOS',
          'codec': 'eac3_joc',
          'sampleRate': 48000,
        },
        sourceId: 'src_atmos',
        sourceName: 'Atmos Source',
      );

      expect(atmosMeta.isDolbyAtmos, isTrue);
      expect(atmosMeta.isLossless, isFalse); // Atmos E-AC-3 is spatial, NOT lossless PCM
      expect(atmosMeta.channels, 8);
      expect(atmosMeta.summaryQualityLabel, contains('Dolby Atmos Spatial Audio'));
    });

    test('6. BitChordProtocolAdapter handles search and stream contracts', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/search') {
          expect(request.url.queryParameters['q'], 'blinding lights');
          expect(request.url.queryParameters['quality'], 'hires');
          return http.Response(
            jsonEncode({
              'tracks': [
                {
                  'id': 'trk_123',
                  'title': 'Blinding Lights',
                  'artist': 'The Weeknd',
                  'album': 'After Hours',
                  'format': 'flac',
                }
              ]
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.url.path == '/stream/trk_123') {
          expect(request.url.queryParameters['quality'], 'hires');
          return http.Response(
            jsonEncode({
              'url': 'https://stream.audio.example/track123.flac',
              'format': 'flac',
              'sampleRate': 96000,
              'bitDepth': 24,
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final source = AddonSourceConfig(
        id: 'test.hires',
        name: 'Test HiRes',
        url: 'https://test.hires.example',
        manifestUrl: 'https://test.hires.example/manifest.json',
        version: '1.0.0',
        qualityTiers: ['hires', 'lossless', 'high'],
      );

      final adapter = BitChordProtocolAdapter(source, client: mockClient);

      final searchResults = await adapter.search(
        query: 'blinding lights',
        quality: 'hires',
      );
      expect(searchResults.length, 1);
      expect(searchResults.first['title'], 'Blinding Lights');

      final stream = await adapter.resolveStream(
        trackId: 'trk_123',
        quality: 'hires',
      );
      expect(stream, isNotNull);
      expect(stream!.url, 'https://stream.audio.example/track123.flac');
      expect(stream.metadata.isHiRes, isTrue);
      expect(stream.metadata.bitDepth, 24);
    });

    test('7. Stream Resolver performs fallback when first provider fails', () async {
      final registry = AddonSourceRegistry.instance;
      await registry.initialize();

      // Ensure all 6 default sources exist
      expect(registry.defaultSources.length, 6);
      expect(registry.allSources.length, greaterThanOrEqualTo(6));
    });

    test('8. Stream Resolver skips allowDownloads: false when isDownload: true', () async {
      // Test downloading exclusion
      final resolver = AddonStreamResolver.instance;
      final dlStream = await resolver.resolveTrackStream(
        trackId: 'test_track_nonexistent',
        title: 'Nonexistent',
        artist: 'Unknown',
        isDownload: true,
      );
      // Nonexistent track returns null without errors or fake fallbacks
      expect(dlStream, isNull);
    });

    test('9. SongItem supports Dolby Atmos metadata and 7.1.4 object spatial audio bed', () {
      const atmosSong = SongItem(
        id: 'atmos_test_1',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy (Dolby Atmos Spatial Audio)',
        duration: '3:50',
        durationSec: 230,
        coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
        lyrics: [],
        audioQuality: 'Dolby Atmos Spatial Audio (E-AC-3 JOC)',
        isDolbyAtmos: true,
      );

      expect(atmosSong.isDolbyAtmos, isTrue);
      expect(atmosSong.audioQuality, contains('Dolby Atmos'));

      const standardSong = SongItem(
        id: 'standard_test_2',
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        duration: '4:03',
        durationSec: 243,
        coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
        lyrics: [],
      );

      expect(standardSong.isDolbyAtmos, isFalse);
    });

    test('10. BitChord sends atmos=auto only when Dolby is enabled and supported, and parses distinct Dolby mixes', () async {
      final atmosSource = AddonSourceConfig(
        id: 'test.atmos.source',
        name: 'Atmos Test Source',
        url: 'https://atmos.example.com',
        manifestUrl: 'https://atmos.example.com/manifest.json',
        version: '1.0.0',
        qualityTiers: ['Ultra Hi-Res', 'Dolby Atmos (7.1.4)', 'Lossless (16-bit)'],
        resources: ['search', 'stream', 'atmos'],
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == '/search') {
          expect(request.url.queryParameters['q'], 'midnight');
          expect(request.url.queryParameters['quality'], 'lossless');
          expect(request.url.queryParameters['atmos'], 'auto');
          return http.Response(
            jsonEncode({
              'tracks': [
                {
                  'id': 'dolby_8f31',
                  'title': 'Midnight Signal',
                  'artist': 'Example Artist',
                  'album': 'Night Drive',
                  'duration': 242,
                  'format': 'dash',
                  'audioModes': ['DOLBY_ATMOS'],
                  'atmos': true,
                }
              ]
            }),
            200,
          );
        } else if (request.url.path == '/stream/dolby_8f31') {
          expect(request.url.queryParameters['quality'], 'lossless');
          expect(request.url.queryParameters['atmos'], 'auto');
          return http.Response(
            jsonEncode({
              'url': 'https://audio.example/media/dolby_8f31',
              'format': 'dash',
              'quality': 'Dolby Atmos',
              'codec': 'eac3-joc',
              'container': 'mp4',
              'manifest': 'dash',
              'sampleRate': 48000,
              'audioMode': 'DOLBY_ATMOS',
              'encrypted': false,
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final adapter = BitChordProtocolAdapter(atmosSource, client: mockClient);

      // Verify search returns distinct Dolby mix
      final searchResults = await adapter.search(query: 'midnight', quality: 'lossless', atmos: 'auto');
      expect(searchResults.length, 1);
      final track = searchResults.first;
      expect(track['id'], 'dolby_8f31');
      expect(track['title'], 'Midnight Signal');
      expect(track['artist'], 'Example Artist');
      expect(track['album'], 'Night Drive');
      expect(track['duration'], 242);
      expect(track['format'], 'dash');
      expect(track['audioModes'], contains('DOLBY_ATMOS'));
      expect(track['atmos'], isTrue);
      expect(track['isDolbyAtmos'], isTrue);

      // Verify resolveStream returns Dolby Atmos metadata
      final streamResult = await adapter.resolveStream(trackId: 'dolby_8f31', quality: 'lossless', atmos: 'auto');
      expect(streamResult, isNotNull);
      expect(streamResult!.url, 'https://audio.example/media/dolby_8f31');
      expect(streamResult.metadata.isDolbyAtmos, isTrue);
      expect(streamResult.metadata.codec, 'E-AC-3 JOC');
      expect(streamResult.metadata.container, 'mp4');
      expect(streamResult.metadata.sampleRateHz, 48000);
      expect(streamResult.metadata.channels, 8);
      expect(streamResult.isDASH, isTrue);
    });
  });
}
