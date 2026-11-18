// Copyright (C) 2026 AuraBeat Project.
// Comprehensive Audio Engine Unit Tests covering PCM Boundary, AudioBlock,
// Output Negotiation, DSD Format, and BitChord 1.0.8 Native Engine Facade.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurabeat/audio_engine/audio_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuraBeat Audio Engine — PCM Encoding & AudioBlock Tests', () {
    test('1. PcmEncoding calculates correct byte sizes and frame alignments', () {
      expect(PcmEncoding.pcm16.bytesPerSample, equals(2));
      expect(PcmEncoding.pcm16.bytesPerFrame(2), equals(4)); // Stereo 16-bit
      expect(PcmEncoding.pcm16.bitsPerSample, equals(16));

      expect(PcmEncoding.pcm24Packed.bytesPerSample, equals(3));
      expect(PcmEncoding.pcm24Packed.bytesPerFrame(2), equals(6)); // Stereo 24-bit
      expect(PcmEncoding.pcm24Packed.bitsPerSample, equals(24));

      expect(PcmEncoding.pcm32Int.bytesPerSample, equals(4));
      expect(PcmEncoding.pcmFloat32.bytesPerSample, equals(4));
      expect(PcmEncoding.pcmFloat32.isFloat, isTrue);

      expect(PcmEncoding.dsdOverPcm.bytesPerSample, equals(3));
      expect(PcmEncoding.dsdOverPcm.isDsd, isTrue);
    });

    test('2. AudioBlock initializes pre-allocated contiguous memory with zero allocations in steady state', () {
      final block = AudioBlock(channelCount: 2, capacityFrames: 1024);
      expect(block.channelCount, equals(2));
      expect(block.capacityFrames, equals(1024));
      expect(block.frameCount, equals(0));
      expect(block.sampleCount, equals(0));
      expect(block.samples.length, equals(2048));

      block.reset(512);
      expect(block.frameCount, equals(512));
      expect(block.sampleCount, equals(1024));

      // Test clear
      block.samples[0] = 0.75;
      block.clear();
      expect(block.frameCount, equals(0));
      expect(block.samples[0], equals(0.0));
    });

    test('3. AudioBlock correctly copies frames between blocks and computes peak & RMS', () {
      final src = AudioBlock(channelCount: 2, capacityFrames: 512);
      final dst = AudioBlock(channelCount: 2, capacityFrames: 512);

      src.reset(4);
      // Frame 0: L=0.5, R=-0.5
      src.samples[0] = 0.5;
      src.samples[1] = -0.5;
      // Frame 1: L=0.8, R=-0.8
      src.samples[2] = 0.8;
      src.samples[3] = -0.8;

      dst.copyFrom(src);
      expect(dst.frameCount, equals(4));
      expect(dst.samples[0], closeTo(0.5, 0.0001));
      expect(dst.samples[2], closeTo(0.8, 0.0001));

      expect(src.computePeak(), closeTo(0.8, 0.0001));
      expect(src.computeRms(), greaterThan(0.0));
    });

    test('4. PcmBoundary decodes 16-bit PCM bytes to normalized Float32 samples', () {
      // 1 stereo frame: 16-bit sample L = 16384 (0.5), R = -32768 (-1.0)
      final bytes = Uint8List(4);
      final bd = ByteData.sublistView(bytes);
      bd.setInt16(0, 16384, Endian.little);
      bd.setInt16(2, -32768, Endian.little);

      final block = AudioBlock(channelCount: 2, capacityFrames: 16);
      final decodedFrames = PcmBoundary.decode(
        inputBytes: bytes,
        encoding: PcmEncoding.pcm16,
        destinationBlock: block,
      );

      expect(decodedFrames, equals(1));
      expect(block.samples[0], closeTo(0.5, 0.0001));
      expect(block.samples[1], closeTo(-1.0, 0.0001));

      // Re-encode to 16-bit
      final encoded = PcmBoundary.encode(
        sourceBlock: block,
        encoding: PcmEncoding.pcm16,
      );
      expect(encoded.length, equals(4));
      final encodedBd = ByteData.sublistView(encoded);
      expect(encodedBd.getInt16(0, Endian.little), equals(16384));
      expect(encodedBd.getInt16(2, Endian.little), equals(-32768));
    });

    test('5. PcmBoundary decodes and encodes 24-bit packed PCM accurately', () {
      // 1 stereo frame: 24-bit sample L = 4194304 (0.5), R = -8388608 (-1.0)
      final bytes = Uint8List(6);
      // L: 4194304 = 0x400000
      bytes[0] = 0x00;
      bytes[1] = 0x00;
      bytes[2] = 0x40;
      // R: -8388608 = 0x800000
      bytes[3] = 0x00;
      bytes[4] = 0x00;
      bytes[5] = 0x80;

      final block = AudioBlock(channelCount: 2, capacityFrames: 16);
      final decodedFrames = PcmBoundary.decode(
        inputBytes: bytes,
        encoding: PcmEncoding.pcm24Packed,
        destinationBlock: block,
      );

      expect(decodedFrames, equals(1));
      expect(block.samples[0], closeTo(0.5, 0.0001));
      expect(block.samples[1], closeTo(-1.0, 0.0001));

      // Re-encode to 24-bit packed
      final encoded = PcmBoundary.encode(
        sourceBlock: block,
        encoding: PcmEncoding.pcm24Packed,
      );
      expect(encoded.length, equals(6));
      expect(encoded[2], equals(0x40));
      expect(encoded[5], equals(0x80));
    });

    test('6. PcmBoundary sanitizes Float32 samples against NaN and Infinities', () {
      expect(PcmBoundary.sanitizeFloat(double.nan), equals(0.0));
      expect(PcmBoundary.sanitizeFloat(double.infinity), equals(1.0));
      expect(PcmBoundary.sanitizeFloat(double.negativeInfinity), equals(-1.0));
      expect(PcmBoundary.sanitizeFloat(0.42), equals(0.42));
    });
  });

  group('AuraBeat Audio Engine — 6-Layer Output Negotiation Tests', () {
    test('7. Direct USB DAC route achieves bit-perfect pass-through for 96kHz / 24-bit FLAC', () {
      const source = SourceDescriptor(
        codec: 'FLAC',
        sampleRateHz: 96000,
        channelCount: 2,
        bitDepth: 24,
      );

      const route = RouteDescriptor(
        kind: AudioRouteKind.usbDac,
        deviceName: 'AudioQuest DragonFly Cobalt',
        isDirectCapable: true,
        advertisedSampleRates: [44100, 48000, 88200, 96000],
        advertisedBitDepths: [16, 24],
      );

      final result = OutputNegotiator.negotiate(
        source: source,
        route: route,
        preferredTransport: OutputTransport.directUsb,
      );

      expect(result.output.isDirect, isTrue);
      expect(result.output.sampleRateHz, equals(96000));
      expect(result.output.encoding, equals(PcmEncoding.pcm24Packed));
      expect(result.isSampleRatePreserved, isTrue);
      expect(result.isBitDepthPreserved, isTrue);
      expect(result.isBitPerfect, isTrue);
      expect(result.output.fallbackReason, equals(FallbackReason.none));
    });

    test('8. Standard Bluetooth AAC route reports route limitation downsampling', () {
      const source = SourceDescriptor(
        codec: 'FLAC',
        sampleRateHz: 96000,
        channelCount: 2,
        bitDepth: 24,
      );

      const route = RouteDescriptor(
        kind: AudioRouteKind.bluetoothA2dp,
        deviceName: 'Sony WH-1000XM5',
        bluetoothCodec: 'AAC',
      );

      final result = OutputNegotiator.negotiate(
        source: source,
        route: route,
      );

      expect(result.output.isDirect, isFalse);
      expect(result.output.sampleRateHz, equals(44100));
      expect(result.output.encoding, equals(PcmEncoding.pcm16));
      expect(result.isSampleRatePreserved, isFalse);
      expect(result.output.fallbackReason, equals(FallbackReason.routeLimitation));
      expect(result.output.fallbackDetail?.contains('downsamples to 44.1 kHz'), isTrue);
    });

    test('9. Built-in speaker route safely enforces 48 kHz / 16-bit ceiling and reports OS policy', () {
      const source = SourceDescriptor(
        codec: 'FLAC',
        sampleRateHz: 192000,
        channelCount: 2,
        bitDepth: 24,
      );

      const route = RouteDescriptor(
        kind: AudioRouteKind.builtInSpeaker,
        deviceName: 'iPhone Built-in Speaker',
      );

      final result = OutputNegotiator.negotiate(
        source: source,
        route: route,
      );

      expect(result.output.sampleRateHz, equals(48000));
      expect(result.output.encoding, equals(PcmEncoding.pcm16));
      expect(result.output.fallbackReason, equals(FallbackReason.osLimitation));
      expect(result.isBitPerfect, isFalse);
    });
  });

  group('AuraBeat Audio Engine — DSD Format & Container Tests', () {
    test('10. DsdFormat correctly computes decimation to 176.4 kHz PCM and duration', () {
      const dsd64 = DsdFormat(
        container: DsdContainer.dsf,
        bitRate: 2822400, // DSD64
        channels: 2,
        sampleCount: 2822400 * 10, // 10 seconds
        dataOffset: 92,
        dataBytes: 7056000,
      );

      expect(dsd64.pcmRate, equals(176400));
      expect(dsd64.decimation, equals(16)); // 2822400 / 176400 = 16
      expect(dsd64.durationSeconds, equals(10.0));
      expect(dsd64.tierLabel, equals('DSD64 (2.8224 MHz)'));

      // Seeking to 5 seconds
      final seekFrame = dsd64.seekFrame(5.0);
      expect(seekFrame, equals(5 * 176400));

      // Accurately reports missing C++ software decimator library
      expect(DsdFormat.hasNativeSoftwareDecimator, isFalse);
    });

    test('11. DsdHeaderParser validates DSF format chunk headers', () {
      // Build 40-byte DSF format chunk
      final chunk = Uint8List(40);
      final bd = ByteData.sublistView(chunk);
      bd.setUint32(0, 1, Endian.little); // format version
      bd.setUint32(4, 0, Endian.little); // format id
      bd.setUint32(8, 2, Endian.little); // channel type (stereo)
      bd.setUint32(12, 2, Endian.little); // channel num
      bd.setUint32(16, 2822400, Endian.little); // sample rate (DSD64)
      bd.setUint32(20, 1, Endian.little); // bits per sample (1 = LSB first)
      bd.setUint64(24, 28224000, Endian.little); // 10s of samples
      bd.setUint32(32, 4096, Endian.little); // block size

      final dsd = DsdHeaderParser.parseDsf(
        formatChunkBytes: chunk,
        dataOffset: 92,
        dataBytes: 7056000,
      );

      expect(dsd.bitRate, equals(2822400));
      expect(dsd.channels, equals(2));
      expect(dsd.leastSignificantBitFirst, isTrue);
      expect(dsd.container, equals(DsdContainer.dsf));
    });

    test('12. DsdHeaderParser rejects corrupt or incomplete chunk headers', () {
      expect(
        () => DsdHeaderParser.parseDsf(
          formatChunkBytes: Uint8List(20), // incomplete (< 40 bytes)
          dataOffset: 0,
          dataBytes: 0,
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('13. DsdHeaderParser parses Philips DSDIFF (DFF) chunk hierarchy', () {
      final bytes = Uint8List(128);
      final bd = ByteData.sublistView(bytes);

      // FRM8 magic
      bytes.setRange(0, 4, [0x46, 0x52, 0x4D, 0x38]); // 'FRM8'
      bd.setUint64(4, 116, Endian.big); // Chunk size
      bytes.setRange(12, 16, [0x44, 0x53, 0x44, 0x20]); // 'DSD ' form type

      // PROP chunk at offset 16
      bytes.setRange(16, 20, [0x50, 0x52, 0x4F, 0x50]); // 'PROP'
      bd.setUint64(20, 52, Endian.big); // PROP size
      bytes.setRange(28, 32, [0x53, 0x4E, 0x44, 0x20]); // 'SND '

      // Sub-chunk FS at offset 32
      bytes.setRange(32, 36, [0x46, 0x53, 0x20, 0x20]); // 'FS  '
      bd.setUint64(36, 4, Endian.big);
      bd.setUint32(44, 2822400, Endian.big); // 2.8224 MHz (DSD64)

      // Sub-chunk CHNL at offset 48
      bytes.setRange(48, 52, [0x43, 0x48, 0x4E, 0x4C]); // 'CHNL'
      bd.setUint64(52, 2, Endian.big);
      bd.setUint16(60, 2, Endian.big); // 2 channels (Stereo)

      // Sub-chunk CMPR at offset 62 (padded to even: 64)
      bytes.setRange(64, 68, [0x43, 0x4D, 0x50, 0x52]); // 'CMPR'
      bd.setUint64(68, 4, Endian.big);
      bytes.setRange(76, 80, [0x44, 0x53, 0x44, 0x20]); // 'DSD ' uncompressed

      // DSD chunk at offset 80
      bytes.setRange(80, 84, [0x44, 0x53, 0x44, 0x20]); // 'DSD '
      bd.setUint64(84, 32, Endian.big); // 32 bytes of DSD data

      final dsd = DsdHeaderParser.parseDff(dffBytes: bytes);
      expect(dsd.container, equals(DsdContainer.dff));
      expect(dsd.bitRate, equals(2822400));
      expect(dsd.channels, equals(2));
      expect(dsd.dataOffset, equals(92));
      expect(dsd.dataBytes, equals(32));
      expect(dsd.leastSignificantBitFirst, isFalse);
    });

    test('14. DsdHeaderParser detects DSF vs DFF container from magic headers', () {
      final dsfMagic = Uint8List.fromList([0x44, 0x53, 0x44, 0x20]); // 'DSD '
      final dffMagic = Uint8List.fromList([0x46, 0x52, 0x4D, 0x38]); // 'FRM8'

      expect(DsdHeaderParser.detectContainer(dsfMagic), equals(DsdContainer.dsf));
      expect(DsdHeaderParser.detectContainer(dffMagic), equals(DsdContainer.dff));

      final invalid = Uint8List.fromList([0x52, 0x49, 0x46, 0x46]); // 'RIFF'
      expect(() => DsdHeaderParser.detectContainer(invalid), throwsA(isA<FormatException>()));
    });

    test('15. DsdFormat reports DoP v1.0 capability accurately against output routes', () {
      const dsd64 = DsdFormat(
        container: DsdContainer.dsf,
        bitRate: 2822400,
        channels: 2,
        sampleCount: 28224000,
        dataOffset: 92,
        dataBytes: 7056000,
      );

      // DoP requires 2822400 / 16 = 176400 Hz (176.4 kHz) PCM at 24-bit
      expect(dsd64.requiredDopPcmRate, equals(176400));

      const dopCapableRoute = RouteDescriptor(
        kind: AudioRouteKind.usbDac,
        deviceName: 'Audiophile USB DAC',
        isDirectCapable: true,
        advertisedSampleRates: [44100, 48000, 96000, 176400, 192000],
        advertisedBitDepths: [16, 24],
      );

      final cap = dsd64.reportDopCapability(dopCapableRoute);
      expect(cap.isSupported, isTrue);
      expect(cap.requiredPcmRateHz, equals(176400));
      expect(cap.requiredBitDepth, equals(24));
      expect(cap.routeSupportsRate, isTrue);
      expect(cap.routeSupportsDepth, isTrue);
    });
  });

  group('AuraBeat Audio Engine — BitChord 1.0.8 Native Engine Facade Tests', () {
    test('16. AuraBeatAudioEngine singleton manages spatial audio state and delegates to platform', () {
      final engine = AuraBeatAudioEngine.instance;
      engine.reset();

      expect(engine.isSpatialAudioEnabled, isFalse);
      engine.setSpatialAudio(true);
      expect(engine.isSpatialAudioEnabled, isTrue);

      engine.setStereoWidening(false);
      expect(engine.isSpatialAudioEnabled, isFalse);
    });

    test('17. AuraBeatAudioEngine singleton configures manual EQ bands and presets', () {
      final engine = AuraBeatAudioEngine.instance;
      engine.reset();

      expect(engine.manualBands.length, equals(7));
      expect(engine.manualBands.every((b) => b == 0.0), isTrue);

      engine.setManualBands([3.0, 2.0, 1.0, 0.0, -1.0, -2.0, -3.0]);
      expect(engine.manualBands, equals([3.0, 2.0, 1.0, 0.0, -1.0, -2.0, -3.0]));

      engine.applyPreset('Bass Booster');
      expect(engine.activePreset, equals('Bass Booster'));
    });

    test('18. AuraBeatAudioEngine singleton sets playback speed, silence skipping, and balance', () {
      final engine = AuraBeatAudioEngine.instance;
      engine.reset();

      engine.setPlaybackSpeed(1.25);
      expect(engine.playbackSpeed, equals(1.25));

      engine.setSilenceSkipping(true);
      expect(engine.isSilenceSkippingEnabled, isTrue);

      engine.setBalance(-0.25);
      expect(engine.balance, equals(-0.25));

      engine.reset();
      expect(engine.playbackSpeed, equals(1.0));
      expect(engine.isSilenceSkippingEnabled, isFalse);
      expect(engine.balance, equals(0.0));
      expect(engine.isSpatialAudioEnabled, isFalse);
    });

    test('19. AuraBeatAudioEngine negotiates audio pipeline output with BitChord 1.0.8 decoder', () {
      final engine = AuraBeatAudioEngine.instance;

      const source = SourceDescriptor(
        codec: 'FLAC',
        sampleRateHz: 48000,
        channelCount: 2,
        bitDepth: 24,
      );

      const route = RouteDescriptor(
        kind: AudioRouteKind.headphones,
        deviceName: 'Wired Headphones',
        advertisedSampleRates: [44100, 48000, 96000],
        advertisedBitDepths: [16, 24],
      );

      final result = engine.negotiate(source: source, route: route);
      expect(result.output.sampleRateHz, equals(48000));
      expect(result.decoder.name, equals('AuraBeat BitChord 1.0.8 CoreAudio Lossless'));
      expect(engine.lastNegotiationResult, equals(result));
    });
  });
}
