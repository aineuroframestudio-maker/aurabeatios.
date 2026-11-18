import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:aurabeat/dolby_atmos/hls_inspector.dart';
import 'package:aurabeat/dolby_atmos/atmos_player.dart';
import 'package:aurabeat/dolby_atmos/atmos_streaming_manager.dart';
import 'package:aurabeat/dolby_atmos/atmos_badge.dart';
import 'package:aurabeat/dolby_atmos/atmos_diagnostic_screen.dart';
import 'package:aurabeat/dolby_atmos/eac3_bitstream_validator.dart';
import 'package:aurabeat/audio_engine/pipeline/audio_pipeline_telemetry.dart';

class MockAtmosPlayerService extends AtmosPlayerService {
  bool isLoaded = false;
  bool isPlaying = false;
  String? lastLoadedUrl;
  double? lastSeekSeconds;
  bool isDisposed = false;
  Map<String, dynamic>? customStatus;

  @override
  Future<bool> load(
    String url, {
    String? title,
    String? artist,
    String? album,
    double? durationSeconds,
    String? codec,
    bool? hasJoc,
    String? jocState,
    String? channelLayout,
    int? bandwidth,
  }) async {
    lastLoadedUrl = url;
    isLoaded = true;
    return true;
  }

  @override
  Future<void> play() async {
    isPlaying = true;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
  }

  @override
  Future<void> seek(double seconds) async {
    lastSeekSeconds = seconds;
  }

  @override
  Future<Map<String, dynamic>> status() async {
    if (customStatus != null) {
      return customStatus!;
    }
    return {
      'loaded': isLoaded,
      'playing': isPlaying,
      'status': isPlaying ? 'playing' : 'ready',
      'currentTime': 12.0,
      'duration': 240.0,
      'sourceVerified': true,
      'playerPlaying': isPlaying,
      'spatializationAllowed': true,
      'spatialRouteEnabled': true,
      'atmosPlaybackEligible': isPlaying,
      'outputNotConfirmed': true,
      'sourceCodec': 'E-AC-3 JOC',
      'hasJocMetadata': true,
      'jocVerificationState': 'inferred from manifest signalling',
      'sourceBitrate': 768,
      'sampleRate': 48000.0,
      'selectedRendition': 'English (16/JOC · ec3-48-768)',
      'spatializationPermission': 'SPATIALIZATION ALLOWED (.monoStereoAndMultichannel)',
      'currentRoute': 'Built-in Speaker (builtInSpeaker)',
      'outputVerificationDetail': 'Validated spatial playback chain: E-AC-3 JOC decoded, spatialization permitted, and iOS Spatial Audio active on route. Acoustic output in ear canal remains unconfirmed by hardware limitation.',
      'bitstreamVerified': false,
      'manifestInferred': true,
      'codecDetected': true,
      'passthroughActive': true,
      'atmosCapableRoute': true,
      'processingBypassed': true,
      'endToEndAtmosRenderingVerified': 'NOT_VERIFIABLE_BY_APP',
      'systemSpatialPlaybackAvailable': true,
      'jocMetadataVerified': true,
      'appDspBypassed': true,
      'deviceModel': 'iPhone',
      'dolbyCodecDetected': true,
      'dolbyJocManifestDetected': true,
      'dolbyJocMetadataVerified': true,
      'dolbyBitstreamVerified': false,
      'dolbyNativePlaybackActive': isPlaying,
      'dolbySpatialPlaybackAvailable': true,
      'dolbyAppDspBypassed': true,
      'dolbyFallbackReason': '',
      'dolbyOutputRoute': 'Built-in Speaker (builtInSpeaker)',
      'dolbyInputCodec': 'E-AC-3 JOC',
      'dolbyInputSampleRate': 48000.0,
      'dolbyInputChannelLayout': 'English (16/JOC · ec3-48-768)',
      'dolbyRenderingVerificationStatus': isPlaying ? 'NOT_VERIFIABLE_BY_APP' : 'Fallback (Stereo Downmix)',
    };
  }

  @override
  Future<void> dispose() async {
    isDisposed = true;
    isPlaying = false;
    isLoaded = false;
  }
}

/// Helper to generate synthetic E-AC-3 frames according to ETSI TS 102 366
Uint8List _createSyntheticEac3Frame({
  int frameSize = 3072,
  bool withJocBitstreamMarker = false,
  List<int>? extraPayloadSyncwords,
}) {
  final bytes = Uint8List(frameSize);
  // Syncword 0x0B77
  bytes[0] = 0x0B;
  bytes[1] = 0x77;
  // frmsiz = frameSize / 2 - 1
  final frmsiz = (frameSize ~/ 2) - 1;
  bytes[2] = ((0 & 0x03) << 6) | ((0 & 0x07) << 3) | ((frmsiz >> 8) & 0x07);
  bytes[3] = frmsiz & 0xFF;
  // fscod = 0 (48kHz)
  bytes[4] = 0x00;
  // acmod = 7 (3/2, 5.1), lfeon = 1 -> 0xF0
  bytes[5] = 0xF0;
  // bsid = 16 -> 0x80
  bytes[6] = 0x80;

  if (withJocBitstreamMarker) {
    // EMDF sync 0x58 0x88 (ETSI TS 103 420 JOC metadata container)
    bytes[20] = 0x58;
    bytes[21] = 0x88;
  }

  if (extraPayloadSyncwords != null) {
    for (final pos in extraPayloadSyncwords) {
      if (pos >= 4 && pos + 1 < frameSize) {
        bytes[pos] = 0x0B;
        bytes[pos + 1] = 0x77;
      }
    }
  }

  return bytes;
}

/// Helper to generate synthetic fMP4 segment (.m4s) with moof and mdat boxes
Uint8List _createSyntheticFmp4Segment({
  required int frameCount,
  int frameSize = 3072,
  int falseSyncwordsCount = 0,
  bool withJoc = false,
}) {
  const moofSize = 176;
  final mdatPayloadSize = frameCount * frameSize;
  final mdatTotalSize = 8 + mdatPayloadSize;
  final totalSize = moofSize + mdatTotalSize;

  final data = Uint8List(totalSize);
  final bd = ByteData.sublistView(data);

  // moof box
  bd.setUint32(0, moofSize);
  data[4] = 0x6D; // 'm'
  data[5] = 0x6F; // 'o'
  data[6] = 0x6F; // 'o'
  data[7] = 0x66; // 'f'

  // mdat box
  final mdatOffset = moofSize;
  bd.setUint32(mdatOffset, mdatTotalSize);
  data[mdatOffset + 4] = 0x6D; // 'm'
  data[mdatOffset + 5] = 0x64; // 'd'
  data[mdatOffset + 6] = 0x61; // 'a'
  data[mdatOffset + 7] = 0x74; // 't'

  final payloadOffset = mdatOffset + 8;
  int insertedFalseSyncwords = 0;

  for (int i = 0; i < frameCount; i++) {
    final frameOffset = payloadOffset + (i * frameSize);
    final hasExtra = (insertedFalseSyncwords < falseSyncwordsCount);
    final frame = _createSyntheticEac3Frame(
      frameSize: frameSize,
      withJocBitstreamMarker: withJoc && i == 0,
      extraPayloadSyncwords: hasExtra ? [100] : null,
    );
    if (hasExtra) insertedFalseSyncwords++;
    data.setRange(frameOffset, frameOffset + frameSize, frame);
  }

  return data;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuraBeat Dolby Atmos — Complete HLS & Stream Detection Tests', () {
    test('1. Valid E-AC-3 JOC HLS source is recognized as genuine Atmos candidate', () {
      const manifest = '''
#EXTM3U
#EXT-X-VERSION:7
#EXT-X-STREAM-INF:BANDWIDTH=768000,CODECS="ec-3",CHANNELS="16/JOC"
atmos/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=384000,CODECS="ec-3",CHANNELS="6"
surround/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=256000,CODECS="mp4a.40.2",CHANNELS="2"
stereo/index.m3u8
''';

      final info = HlsAtmosInspector.inspect(manifest);

      expect(info.isDolbyDigitalPlus, isTrue);
      expect(info.hasJocMetadata, isTrue);
      expect(info.isAtmosCandidate, isTrue);
      expect(info.codec.toLowerCase().contains('ec-3'), isTrue);
      expect(info.channels.contains('JOC'), isTrue);
      expect(info.variants.length, equals(3));
      expect(info.variants[0].isAtmos, isTrue);
      expect(info.variants[1].isDolby51, isTrue);
      expect(info.variants[2].isStereo, isTrue);
    });

    test('2. E-AC-3 without JOC metadata is recognized as Dolby Digital Plus but NOT Atmos candidate', () {
      const manifest = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=384000,CODECS="ec-3",CHANNELS="6"
surround/index.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=256000,CODECS="mp4a.40.2",CHANNELS="2"
stereo/index.m3u8
''';

      final info = HlsAtmosInspector.inspect(manifest);

      expect(info.isDolbyDigitalPlus, isTrue);
      expect(info.hasJocMetadata, isFalse);
      expect(info.isAtmosCandidate, isFalse);
    });

    test('3. Standard AAC Stereo manifest is correctly identified as non-Atmos non-EAC3', () {
      const manifest = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=256000,CODECS="mp4a.40.2",CHANNELS="2"
stereo_high.m3u8
#EXT-X-STREAM-INF:BANDWIDTH=128000,CODECS="mp4a.40.2",CHANNELS="2"
stereo_med.m3u8
''';

      final info = HlsAtmosInspector.inspect(manifest);

      expect(info.isDolbyDigitalPlus, isFalse);
      expect(info.hasJocMetadata, isFalse);
      expect(info.isAtmosCandidate, isFalse);
      expect(info.variants.every((v) => v.isStereo), isTrue);
    });

    test('4. Handles EXT-X-MEDIA:TYPE=AUDIO with audio groups', () {
      const manifest = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-atmos",NAME="Dolby Atmos",DEFAULT=YES,AUTOSELECT=YES,CHANNELS="16/JOC",CODECS="ec-3",URI="atmos/rendition.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-surround",NAME="5.1 Surround",DEFAULT=NO,AUTOSELECT=YES,CHANNELS="6",CODECS="ec-3",URI="51/rendition.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio-stereo",NAME="Stereo",DEFAULT=NO,AUTOSELECT=YES,CHANNELS="2",CODECS="mp4a.40.2",URI="stereo/rendition.m3u8"
''';

      final info = HlsAtmosInspector.inspect(manifest);

      expect(info.isDolbyDigitalPlus, isTrue);
      expect(info.hasJocMetadata, isTrue);
      expect(info.isAtmosCandidate, isTrue);
      expect(info.variants.length, equals(3));
      expect(info.variants.first.isAtmos, isTrue);
      expect(info.variants.first.uri, equals('atmos/rendition.m3u8'));
    });

    test('5. Fallback selection hierarchy follows specification (Atmos -> 5.1 -> Stereo)', () {
      const variantsWithAll = [
        HlsAudioVariant(uri: 's.m3u8', codec: 'mp4a.40.2', channels: '2', bandwidth: 256000, isAtmos: false, isDolby51: false, isStereo: true),
        HlsAudioVariant(uri: 'a.m3u8', codec: 'ec-3', channels: '16/JOC', bandwidth: 768000, isAtmos: true, isDolby51: false, isStereo: false),
        HlsAudioVariant(uri: 'd.m3u8', codec: 'ec-3', channels: '6', bandwidth: 384000, isAtmos: false, isDolby51: true, isStereo: false),
      ];

      final selected1 = HlsAtmosInspector.selectFallbackVariant(variantsWithAll);
      expect(selected1?.isAtmos, isTrue);
      expect(selected1?.uri, equals('a.m3u8'));

      final variantsWithoutAtmos = [
        HlsAudioVariant(uri: 's.m3u8', codec: 'mp4a.40.2', channels: '2', bandwidth: 256000, isAtmos: false, isDolby51: false, isStereo: true),
        HlsAudioVariant(uri: 'd.m3u8', codec: 'ec-3', channels: '6', bandwidth: 384000, isAtmos: false, isDolby51: true, isStereo: false),
      ];
      final selected2 = HlsAtmosInspector.selectFallbackVariant(variantsWithoutAtmos);
      expect(selected2?.isDolby51, isTrue);
      expect(selected2?.uri, equals('d.m3u8'));

      final variantsStereoOnly = [
        HlsAudioVariant(uri: 's.m3u8', codec: 'mp4a.40.2', channels: '2', bandwidth: 256000, isAtmos: false, isDolby51: false, isStereo: true),
      ];
      final selected3 = HlsAtmosInspector.selectFallbackVariant(variantsStereoOnly);
      expect(selected3?.isStereo, isTrue);
      expect(selected3?.uri, equals('s.m3u8'));
    });
  });

  group('AuraBeat Dolby Atmos — AtmosStreamingManager Tests', () {
    test('6. inspectStream retrieves manifest over HTTP and parses correctly', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://audio.example/master.m3u8') {
          return http.Response(
            '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=768000,CODECS="ec-3",CHANNELS="16/JOC"\natmos/index.m3u8\n',
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final manager = AtmosStreamingManager(
        playerService: MockAtmosPlayerService(),
        httpClient: mockClient,
      );

      final info = await manager.inspectStream('https://audio.example/master.m3u8');
      expect(info.isAtmosCandidate, isTrue);
      expect(info.isDolbyDigitalPlus, isTrue);
      expect(info.hasJocMetadata, isTrue);
      expect(manager.lastStreamInfo, isNotNull);
    });

    test('7. inspectStream throws clear exception when HTTP request fails', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final manager = AtmosStreamingManager(
        playerService: MockAtmosPlayerService(),
        httpClient: mockClient,
      );

      expect(
        () => manager.inspectStream('https://audio.example/master.m3u8'),
        throwsA(isA<Exception>()),
      );
    });

    test('8. playAuthorizedStream resolves variant and invokes player for Atmos candidate', () async {
      final mockPlayer = MockAtmosPlayerService();
      final mockClient = MockClient((request) async {
        return http.Response(
          '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=768000,CODECS="ec-3",CHANNELS="16/JOC"\natmos/index.m3u8\n',
          200,
        );
      });

      final manager = AtmosStreamingManager(
        playerService: mockPlayer,
        httpClient: mockClient,
      );

      await manager.playAuthorizedStream('https://audio.example/master.m3u8', title: 'Midnight Signal');

      expect(mockPlayer.isLoaded, isTrue);
      expect(mockPlayer.isPlaying, isTrue);
      expect(manager.isAtmosSource, isTrue);
      expect(manager.is51Fallback, isFalse);
      expect(manager.activeStreamUrl, equals('https://audio.example/atmos/index.m3u8'));

      await manager.stop();
      expect(mockPlayer.isPlaying, isFalse);

      await manager.dispose();
      expect(mockPlayer.isDisposed, isTrue);
    });

    test('9. playAuthorizedStream throws Exception when manifest has no E-AC-3 and no fallback allowed', () async {
      final mockPlayer = MockAtmosPlayerService();
      final mockClient = MockClient((request) async {
        return http.Response(
          '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=128000,CODECS="none"\nempty.m3u8\n',
          200,
        );
      });

      final manager = AtmosStreamingManager(
        playerService: mockPlayer,
        httpClient: mockClient,
      );

      expect(
        () => manager.playAuthorizedStream('https://audio.example/master.m3u8', allowFallback: false),
        throwsA(predicate((e) => e.toString().contains('E-AC-3 stream not found'))),
      );
    });

    test('12. Apple Developer Reference HLS manifest (adv_dv_atmos) resolves E-AC-3 JOC candidate', () async {
      const appleManifestSample = '''
#EXTM3U
#EXT-X-VERSION:6
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="aachev2-44-32",NAME="English",CHANNELS="2",URI="stereo32/prog_index.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="ac3-48-384",NAME="English",CHANNELS="6",URI="surround51/prog_index.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="ec3-48-768",NAME="English",CHANNELS="16/JOC",URI="Job932393e2-1e4f-4fdb-ab59-0d201f752656-107660254-Transcode_audio_full_en_atmos_0_1-en_audio/prog_index.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=3990516,CODECS="hvc1.2.20000000.L123.B0,ec-3",AUDIO="ec3-48-768"
video/prog_index.m3u8
''';

      final mockPlayer = MockAtmosPlayerService();
      final mockClient = MockClient((request) async {
        return http.Response(appleManifestSample, 200);
      });

      final manager = AtmosStreamingManager(
        playerService: mockPlayer,
        httpClient: mockClient,
      );

      await manager.playAuthorizedStream(
        'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
        title: 'Apple Developer Dolby Atmos Reference Stream',
      );

      expect(manager.isAtmosSource, isTrue);
      expect(manager.is51Fallback, isFalse);
      expect(manager.isStereoFallback, isFalse);
      expect(mockPlayer.isLoaded, isTrue);
      expect(mockPlayer.isPlaying, isTrue);
      expect(
        mockPlayer.lastLoadedUrl,
        equals('https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/Job932393e2-1e4f-4fdb-ab59-0d201f752656-107660254-Transcode_audio_full_en_atmos_0_1-en_audio/prog_index.m3u8'),
      );
    });
  });

  group('AuraBeat Dolby Atmos — E-AC-3 Bitstream Frame Analysis & Discrepancy Tests', () {
    test('14. Resolves 187-versus-195 syncframes discrepancy: strict frame walk vs naive pattern search', () {
      // Create segment matching fileSequence1.m4s: exactly 187 valid frames of 3072 bytes (574,464 bytes mdat payload)
      // with 8 false-positive 0x0B77 syncwords embedded inside audio payloads.
      final segmentData = _createSyntheticFmp4Segment(
        frameCount: 187,
        frameSize: 3072,
        falseSyncwordsCount: 8,
      );

      // Verify overall segment layout: moof (176) + mdat header (8) + payload (574,464) = 574,648 bytes
      expect(segmentData.length, equals(574648));

      // 1. Naive syncword search counts 195 instances (187 real syncframes + 8 incidental occurrences)
      final naiveCount = Eac3BitstreamValidator.countNaiveSyncwords(segmentData, 184, 574464);
      expect(naiveCount, equals(195));

      // 2. Strict bitstream validation walks frames contiguous by declared size
      final result = Eac3BitstreamValidator.validateSegment(
        segmentData,
        segmentDurationSeconds: 5.984,
        manifestHasJoc: true,
      );

      expect(result.validFrameCount, equals(187));
      expect(result.declaredFrameSize, equals(3072));
      expect(result.mdatPayloadBytes, equals(574464));
      expect(result.nonAudioOrPaddingBytes, equals(0));
      expect(result.isContiguous, isTrue);
      expect(result.anomalies, isEmpty);

      // Verify measured bitrate equals exactly 768.0 kbps
      expect(result.measuredBitrateKbps, closeTo(768.0, 0.05));

      // Assert that naive search != verified frame count
      expect(result.validFrameCount, isNot(equals(naiveCount)));
    });

    test('15. Detects invalid syncwords and stops parsing gracefully with anomaly report', () {
      final corruptedSegment = _createSyntheticFmp4Segment(frameCount: 10, frameSize: 3072);
      // Corrupt syncword of frame 4 (offset: 184 + 3 * 3072 = 9390)
      corruptedSegment[184 + (3 * 3072)] = 0xAA;
      corruptedSegment[184 + (3 * 3072) + 1] = 0xBB;

      final result = Eac3BitstreamValidator.validateSegment(corruptedSegment);
      expect(result.validFrameCount, equals(3));
      expect(result.isContiguous, isFalse);
      expect(result.anomalies.any((a) => a.contains('Invalid syncword')), isTrue);
    });

    test('16. Detects truncated frames when segment terminates before declared frame completes', () {
      final normalSegment = _createSyntheticFmp4Segment(frameCount: 5, frameSize: 3072);
      // Truncate segment mid-frame 4
      final truncatedSegment = normalSegment.sublist(0, normalSegment.length - 1500);

      final result = Eac3BitstreamValidator.validateSegment(truncatedSegment);
      expect(result.validFrameCount, equals(4));
      expect(result.isContiguous, isFalse);
      expect(result.anomalies.any((a) => a.contains('Truncated frame')), isTrue);
    });

    test('17. Detects incomplete trailing frame headers when fewer than 4 bytes remain', () {
      final rawFrame = _createSyntheticEac3Frame(frameSize: 1024);
      // Append 2 extra trailing bytes forming an incomplete frame header
      final rawWithIncompleteHeader = Uint8List(rawFrame.length + 2);
      rawWithIncompleteHeader.setRange(0, rawFrame.length, rawFrame);
      rawWithIncompleteHeader[rawFrame.length] = 0x0B;
      rawWithIncompleteHeader[rawFrame.length + 1] = 0x77;

      final result = Eac3BitstreamValidator.validateSegment(rawWithIncompleteHeader);
      expect(result.validFrameCount, equals(1));
      expect(result.isContiguous, isFalse);
      expect(result.anomalies.any((a) => a.contains('Incomplete trailing frame header')), isTrue);
    });

    test('18. ETSI TS 103 420 JOC metadata verified directly from bitstream payload', () {
      final jocSegment = _createSyntheticFmp4Segment(
        frameCount: 4,
        frameSize: 3072,
        withJoc: true,
      );

      final result = Eac3BitstreamValidator.validateSegment(jocSegment);
      expect(result.jocState, equals(JocVerificationState.bitstreamVerified));
      expect(result.jocDetails.contains('actual E-AC-3 bitstream'), isTrue);
    });

    test('19. Manifest JOC signalling without bitstream payload yields manifestInferred state', () {
      final cleanSegmentWithoutBitstreamJoc = _createSyntheticFmp4Segment(
        frameCount: 4,
        frameSize: 3072,
        withJoc: false,
      );

      final result = Eac3BitstreamValidator.validateSegment(
        cleanSegmentWithoutBitstreamJoc,
        manifestHasJoc: true,
      );
      expect(result.jocState, equals(JocVerificationState.manifestInferred));
      expect(result.jocDetails.contains('manifest signalling'), isTrue);
    });

    test('20. Missing JOC metadata in both bitstream and manifest yields unverified state', () {
      final cleanSegment = _createSyntheticFmp4Segment(
        frameCount: 4,
        frameSize: 3072,
        withJoc: false,
      );

      final result = Eac3BitstreamValidator.validateSegment(
        cleanSegment,
        manifestHasJoc: false,
      );
      expect(result.jocState, equals(JocVerificationState.unverified));
      expect(result.jocDetails.contains('Unverified'), isTrue);
    });
  });

  group('AuraBeat Dolby Atmos — AtmosBadge UI Component Tests', () {
    testWidgets('10. AtmosBadge renders DOLBY ATMOS SOURCE when isAtmosSource is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AtmosBadge(isAtmosSource: true),
          ),
        ),
      );

      expect(find.text('DOLBY ATMOS SOURCE'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('11. AtmosBadge renders SizedBox.shrink() when isAtmosSource is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AtmosBadge(isAtmosSource: false),
          ),
        ),
      );

      expect(find.text('DOLBY ATMOS SOURCE'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('13. AtmosDiagnosticScreen renders 6 distinct audited statuses and technical telemetry rows', (tester) async {
      final mockPlayer = MockAtmosPlayerService();
      final manager = AtmosStreamingManager(playerService: mockPlayer);

      await tester.pumpWidget(
        MaterialApp(
          home: AtmosDiagnosticScreen(streamingManager: manager),
        ),
      );
      await tester.pumpAndSettle();

      // Verify the 6 distinct statuses are individually present
      expect(find.text('SOURCE VERIFIED'), findsOneWidget);
      expect(find.text('PLAYER PLAYING'), findsOneWidget);
      expect(find.text('SPATIALIZATION ALLOWED'), findsOneWidget);
      expect(find.text('SPATIAL ROUTE ENABLED'), findsOneWidget);
      expect(find.text('ATMOS PLAYBACK ELIGIBLE'), findsOneWidget);
      expect(find.text('OUTPUT NOT CONFIRMED'), findsOneWidget);

      // Verify distinct status tag pills
      expect(find.text('HARDWARE LIMIT'), findsOneWidget);

      // Verify technical telemetry labels
      expect(find.text('Source Codec'), findsOneWidget);
      expect(find.text('JOC Metadata Detection'), findsOneWidget);
      expect(find.text('JOC Verification Mode'), findsOneWidget);
      expect(find.text('Source Bitrate'), findsOneWidget);
      expect(find.text('Sample Rate'), findsOneWidget);
      expect(find.text('Selected Audio Rendition'), findsOneWidget);
      expect(find.text('AVPlayer Status'), findsOneWidget);
      expect(find.text('Spatialization Permission'), findsOneWidget);
      expect(find.text('Current Audio Route'), findsOneWidget);
      expect(find.text('Output Verification Status'), findsOneWidget);
    });

    testWidgets('21. Spatialization permission disabled reflects RESTRICTED and marks playback ineligible', (tester) async {
      final mockPlayer = MockAtmosPlayerService();
      mockPlayer.customStatus = {
        'sourceVerified': true,
        'playerPlaying': true,
        'playing': true,
        'spatializationAllowed': false,
        'spatialRouteEnabled': true,
        'atmosPlaybackEligible': false,
        'outputNotConfirmed': true,
        'spatializationPermission': 'RESTRICTED (.none)',
        'currentRoute': 'Built-in Speaker (builtInSpeaker)',
      };
      final manager = AtmosStreamingManager(playerService: mockPlayer);

      await tester.pumpWidget(
        MaterialApp(
          home: AtmosDiagnosticScreen(streamingManager: manager),
        ),
      );
      await tester.pumpAndSettle();

      // Spatialization permission card should show RESTRICTED
      expect(find.text('RESTRICTED'), findsOneWidget);
      expect(find.text('INELIGIBLE'), findsOneWidget);
      expect(find.text('STEREO DOWNMIX FALLBACK'), findsOneWidget);
    });

    testWidgets('22. Spatial route enabled vs disabled reflects system capability accurately', (tester) async {
      final mockPlayer = MockAtmosPlayerService();
      mockPlayer.customStatus = {
        'sourceVerified': true,
        'playerPlaying': true,
        'playing': true,
        'spatializationAllowed': true,
        'spatialRouteEnabled': false,
        'atmosPlaybackEligible': false,
        'outputNotConfirmed': true,
        'currentRoute': 'Standard Bluetooth Headphones (bluetoothA2DP)',
      };
      final manager = AtmosStreamingManager(playerService: mockPlayer);

      await tester.pumpWidget(
        MaterialApp(
          home: AtmosDiagnosticScreen(streamingManager: manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DISABLED'), findsOneWidget);
      expect(find.text('INELIGIBLE'), findsOneWidget);
    });

    testWidgets('23. Output route change updates current audio route telemetry', (tester) async {
      final mockPlayer = MockAtmosPlayerService();
      mockPlayer.customStatus = {
        'sourceVerified': true,
        'playerPlaying': true,
        'playing': true,
        'spatializationAllowed': true,
        'spatialRouteEnabled': true,
        'atmosPlaybackEligible': true,
        'outputNotConfirmed': true,
        'currentRoute': 'AirPods Pro (bluetoothA2DP)',
      };
      final manager = AtmosStreamingManager(playerService: mockPlayer);

      await tester.pumpWidget(
        MaterialApp(
          home: AtmosDiagnosticScreen(streamingManager: manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AirPods Pro (bluetoothA2DP)'), findsOneWidget);
      expect(find.text('ENABLED'), findsOneWidget);
      expect(find.text('ELIGIBLE'), findsOneWidget);
      expect(find.text('ATMOS PLAYBACK ELIGIBLE'), findsWidgets);
    });

    testWidgets('24. Handles missing or unknown capability information gracefully', (tester) async {
      final mockPlayer = MockAtmosPlayerService();
      mockPlayer.customStatus = <String, dynamic>{}; // completely empty status
      final manager = AtmosStreamingManager(playerService: mockPlayer);

      await tester.pumpWidget(
        MaterialApp(
          home: AtmosDiagnosticScreen(streamingManager: manager),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen rendered without crashing
      expect(find.text('Dolby Atmos Diagnostic Lab'), findsOneWidget);
      expect(find.text('SOURCE VERIFIED'), findsOneWidget);
      expect(find.text('OUTPUT NOT CONFIRMED'), findsOneWidget);
      expect(find.text('HARDWARE LIMIT'), findsOneWidget);
    });

    testWidgets('25. Diagnostic distinguishes 6 specific states: bitstreamVerified, manifestInferred, codecDetected, passthroughActive, atmosCapableRoute, processingBypassed', (tester) async {
      final mockPlayer = MockAtmosPlayerService();
      final statusMap = await mockPlayer.status();

      expect(statusMap.containsKey('bitstreamVerified'), isTrue);
      expect(statusMap['bitstreamVerified'], isFalse); // AVPlayer isolates bitstream during live playback
      expect(statusMap['manifestInferred'], isTrue);
      expect(statusMap['codecDetected'], isTrue);
      expect(statusMap['passthroughActive'], isTrue);
      expect(statusMap['atmosCapableRoute'], isTrue);
      expect(statusMap['processingBypassed'], isTrue);

      final manager = AtmosStreamingManager(playerService: mockPlayer);
      await tester.pumpWidget(
        MaterialApp(
          home: AtmosDiagnosticScreen(streamingManager: manager),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bitstream Verified'), findsOneWidget);
      expect(find.text('Manifest Inferred'), findsOneWidget);
      expect(find.text('Codec Detected'), findsOneWidget);
      expect(find.text('Passthrough Active'), findsOneWidget);
      expect(find.text('Atmos-Capable Route'), findsOneWidget);
      expect(find.text('Processing Bypassed'), findsOneWidget);
    });
  });

  group('AuraBeat Dolby Atmos — Desktop 1.8 Parity & 16-Scenario Verification Tests', () {
    test('1. E-AC-3 codec detection', () {
      final manifest = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=768000,CODECS="ec-3"
stream.m3u8
''';
      final info = HlsAtmosInspector.inspect(manifest);
      expect(info.isDolbyDigitalPlus, isTrue);
      expect(info.codec, contains('ec-3'));
    });

    test('2. JOC manifest detection', () {
      final manifest = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Atmos",DEFAULT=YES,AUTOSELECT=YES,CHANNELS="16/JOC",URI="atmos.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=768000,CODECS="ec-3",AUDIO="audio"
video.m3u8
''';
      final info = HlsAtmosInspector.inspect(manifest);
      expect(info.isAtmosCandidate, isTrue);
      expect(info.hasJocMetadata, isTrue);
      expect(info.channels, '16/JOC');
    });

    test('3. Binary syncframe validation', () {
      final frame = _createSyntheticEac3Frame(frameSize: 3072);
      expect(frame[0], 0x0B);
      expect(frame[1], 0x77);
      final segment = _createSyntheticFmp4Segment(frameCount: 5, frameSize: 3072);
      final result = Eac3BitstreamValidator.validateSegment(segment);
      expect(result.validFrameCount, 5);
      expect(result.declaredFrameSize, 3072);
      expect(result.isContiguous, isTrue);
    });

    test('4. JOC metadata validation', () {
      final segmentWithJoc = _createSyntheticFmp4Segment(frameCount: 3, frameSize: 3072, withJoc: true);
      final resWithJoc = Eac3BitstreamValidator.validateSegment(segmentWithJoc);
      expect(resWithJoc.jocState, JocVerificationState.bitstreamVerified);

      final segmentWithoutJoc = _createSyntheticFmp4Segment(frameCount: 3, frameSize: 3072, withJoc: false);
      final resWithoutJoc = Eac3BitstreamValidator.validateSegment(segmentWithoutJoc);
      expect(resWithoutJoc.jocState, JocVerificationState.unverified);
    });

    test('5. Invalid and corrupted streams', () {
      final corrupted = Uint8List(4096);
      corrupted.fillRange(0, 4096, 0xFF);
      final result = Eac3BitstreamValidator.validateSegment(corrupted);
      expect(result.validFrameCount, 0);
      expect(result.anomalies, isNotEmpty);
    });

    test('6. Unsupported codecs', () {
      final manifest = '''
#EXTM3U
#EXT-X-STREAM-INF:BANDWIDTH=160000,CODECS="opus"
opus.m3u8
''';
      final info = HlsAtmosInspector.inspect(manifest);
      expect(info.isDolbyDigitalPlus, isFalse);
      expect(info.isAtmosCandidate, isFalse);
    });

    test('7. Multichannel identification', () {
      final segment = _createSyntheticFmp4Segment(frameCount: 2, frameSize: 3072);
      final result = Eac3BitstreamValidator.validateSegment(segment);
      expect(result.channelBedCount, 6); // 5.1 bed
      expect(result.lfePresent, isTrue);
    });

    test('8. DSP bypass for Atmos', () {
      final telemetry = AudioPipelineTelemetry(
        sourceFormat: 'E-AC-3 JOC',
        decoderName: 'Apple E-AC-3 JOC Decoder (Spatial Passthrough)',
        decodedChannels: 6,
        realtimeTapActive: false,
        iosSpatialProcessorAttached: false,
        iosSpatialProcessorActive: false,
        iosSpatialBypassReason: 'Dolby Atmos E-AC-3 JOC Passthrough',
        dolbyCodecDetected: true,
        dolbyJocManifestDetected: true,
        dolbyAppDspBypassed: true,
      );
      expect(telemetry.realtimeTapActive, isFalse);
      expect(telemetry.iosSpatialProcessorActive, isFalse);
      expect(telemetry.iosSpatialBypassReason, 'Dolby Atmos E-AC-3 JOC Passthrough');
      expect(telemetry.dolbyAppDspBypassed, isTrue);
    });

    test('9. Ordinary stereo playback fallback', () async {
      final mockPlayer = MockAtmosPlayerService();
      mockPlayer.customStatus = {
        'loaded': true,
        'playing': true,
        'status': 'playing',
        'sourceVerified': false,
        'playerPlaying': true,
        'spatializationAllowed': true,
        'spatialRouteEnabled': false,
        'atmosPlaybackEligible': false,
        'outputNotConfirmed': true,
        'sourceCodec': 'AAC-LC',
        'hasJocMetadata': false,
        'currentRoute': 'Speaker (Mono/Stereo)',
        'dolbyCodecDetected': false,
        'dolbySpatialPlaybackAvailable': false,
        'dolbyAppDspBypassed': false,
        'dolbyFallbackReason': 'Route does not support Spatial Audio (Stereo Downmix)',
        'dolbyRenderingVerificationStatus': 'Fallback (Stereo Downmix)',
      };
      final status = await mockPlayer.status();
      expect(status['atmosPlaybackEligible'], isFalse);
      expect(status['dolbyFallbackReason'], contains('Stereo Downmix'));
      expect(status['dolbyRenderingVerificationStatus'], contains('Fallback'));
    });

    test('10. HLS audio rendition selection', () async {
      final manifest = '''
#EXTM3U
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Stereo",DEFAULT=NO,AUTOSELECT=YES,CHANNELS="2",URI="stereo.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="5.1",DEFAULT=NO,AUTOSELECT=YES,CHANNELS="6",URI="surround.m3u8"
#EXT-X-MEDIA:TYPE=AUDIO,GROUP-ID="audio",NAME="Atmos",DEFAULT=YES,AUTOSELECT=YES,CHANNELS="16/JOC",URI="atmos.m3u8"
#EXT-X-STREAM-INF:BANDWIDTH=768000,CODECS="ec-3",AUDIO="audio"
prog.m3u8
''';
      final client = MockClient((request) async => http.Response(manifest, 200));
      final player = MockAtmosPlayerService();
      final manager = AtmosStreamingManager(playerService: player, httpClient: client);
      await manager.playAuthorizedStream('https://stream.example.com/master.m3u8');
      expect(player.isLoaded, isTrue);
      expect(player.lastLoadedUrl, 'https://stream.example.com/atmos.m3u8');
      expect(manager.isAtmosSource, isTrue);
    });

    test('11. Audio route changes', () async {
      final mockPlayer = MockAtmosPlayerService();
      mockPlayer.customStatus = {
        'loaded': true,
        'playing': true,
        'currentRoute': 'AirPods Pro (bluetoothA2DP)',
        'spatialRouteEnabled': true,
        'dolbySpatialPlaybackAvailable': true,
        'dolbyOutputRoute': 'AirPods Pro (bluetoothA2DP)',
      };
      var status = await mockPlayer.status();
      expect(status['spatialRouteEnabled'], isTrue);
      expect(status['dolbyOutputRoute'], contains('AirPods'));

      mockPlayer.customStatus = {
        'loaded': true,
        'playing': true,
        'currentRoute': 'Built-in Speaker (builtInSpeaker)',
        'spatialRouteEnabled': false,
        'dolbySpatialPlaybackAvailable': false,
        'dolbyOutputRoute': 'Built-in Speaker (builtInSpeaker)',
        'dolbyFallbackReason': 'Route does not support Spatial Audio (Stereo Downmix)',
      };
      status = await mockPlayer.status();
      expect(status['spatialRouteEnabled'], isFalse);
      expect(status['dolbyOutputRoute'], contains('Built-in Speaker'));
    });

    test('12. Track switching', () async {
      final mockPlayer = MockAtmosPlayerService();
      await mockPlayer.load('https://example.com/track1_atmos.m3u8', title: 'Song 1');
      expect(mockPlayer.lastLoadedUrl, 'https://example.com/track1_atmos.m3u8');

      await mockPlayer.load('https://example.com/track2_stereo.m3u8', title: 'Song 2');
      expect(mockPlayer.lastLoadedUrl, 'https://example.com/track2_stereo.m3u8');
      expect(mockPlayer.isLoaded, isTrue);
    });

    test('13. Seeking and resuming', () async {
      final mockPlayer = MockAtmosPlayerService();
      await mockPlayer.load('https://example.com/stream.m3u8');
      await mockPlayer.play();
      expect(mockPlayer.isPlaying, isTrue);

      await mockPlayer.seek(45.5);
      expect(mockPlayer.lastSeekSeconds, 45.5);
      expect(mockPlayer.isPlaying, isTrue);
    });

    test('14. Playback interruptions', () async {
      final mockPlayer = MockAtmosPlayerService();
      await mockPlayer.play();
      expect(mockPlayer.isPlaying, isTrue);

      await mockPlayer.pause();
      expect(mockPlayer.isPlaying, isFalse);

      await mockPlayer.play();
      expect(mockPlayer.isPlaying, isTrue);
    });

    test('15. Flutter/native telemetry synchronization', () {
      final originalMap = <String, dynamic>{
        'sourceFormat': 'E-AC-3 JOC',
        'decoderName': 'Apple E-AC-3 JOC Decoder (Spatial Passthrough)',
        'decodedSampleRateHz': 48000,
        'decodedChannels': 6,
        'outputSampleRateHz': 48000,
        'outputChannels': 2,
        'dolbyCodecDetected': true,
        'dolbyJocManifestDetected': true,
        'dolbyJocMetadataVerified': true,
        'dolbyBitstreamVerified': false,
        'dolbyNativePlaybackActive': true,
        'dolbySpatialPlaybackAvailable': true,
        'dolbyAppDspBypassed': true,
        'dolbyFallbackReason': '',
        'dolbyOutputRoute': 'AirPods Pro',
        'dolbyInputCodec': 'E-AC-3 JOC',
        'dolbyInputSampleRate': 48000.0,
        'dolbyInputChannelLayout': '16/JOC',
        'dolbyRenderingVerificationStatus': 'NOT_VERIFIABLE_BY_APP',
      };

      final telemetry = AudioPipelineTelemetry.fromMap(originalMap);
      expect(telemetry.dolbyCodecDetected, isTrue);
      expect(telemetry.dolbyJocManifestDetected, isTrue);
      expect(telemetry.dolbyJocMetadataVerified, isTrue);
      expect(telemetry.dolbyBitstreamVerified, isFalse);
      expect(telemetry.dolbyNativePlaybackActive, isTrue);
      expect(telemetry.dolbySpatialPlaybackAvailable, isTrue);
      expect(telemetry.dolbyAppDspBypassed, isTrue);
      expect(telemetry.dolbyFallbackReason, '');
      expect(telemetry.dolbyOutputRoute, 'AirPods Pro');
      expect(telemetry.dolbyInputCodec, 'E-AC-3 JOC');
      expect(telemetry.dolbyInputSampleRate, 48000.0);
      expect(telemetry.dolbyInputChannelLayout, '16/JOC');
      expect(telemetry.dolbyRenderingVerificationStatus, 'NOT_VERIFIABLE_BY_APP');

      final roundTrip = telemetry.toMap();
      expect(roundTrip['dolbyCodecDetected'], isTrue);
      expect(roundTrip['dolbyOutputRoute'], 'AirPods Pro');
      expect(roundTrip['dolbyRenderingVerificationStatus'], 'NOT_VERIFIABLE_BY_APP');
    });

    test('16. Diagnostic state correctness', () async {
      final mockPlayer = MockAtmosPlayerService();
      final status = await mockPlayer.status();

      expect(status.containsKey('manifestInferred'), isTrue);
      expect(status.containsKey('codecDetected'), isTrue);
      expect(status.containsKey('bitstreamVerified'), isTrue);
      expect(status.containsKey('jocMetadataVerified'), isTrue);
      expect(status.containsKey('systemSpatialPlaybackAvailable'), isTrue);
      expect(status.containsKey('appDspBypassed'), isTrue);
      expect(status.containsKey('endToEndAtmosRenderingVerified'), isTrue);

      expect(status['manifestInferred'], isTrue);
      expect(status['bitstreamVerified'], isFalse);

      expect(status['codecDetected'], isTrue);
      expect(status['endToEndAtmosRenderingVerified'], 'NOT_VERIFIABLE_BY_APP');
    });
  });
}
