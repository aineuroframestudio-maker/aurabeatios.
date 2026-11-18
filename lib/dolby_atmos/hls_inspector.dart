class AtmosStreamInfo {
  final bool isDolbyDigitalPlus;
  final bool hasJocMetadata;
  final bool isAtmosCandidate;
  final String codec;
  final String channels;
  final int? bandwidth;
  final List<HlsAudioVariant> variants;

  const AtmosStreamInfo({
    required this.isDolbyDigitalPlus,
    required this.hasJocMetadata,
    required this.isAtmosCandidate,
    required this.codec,
    required this.channels,
    this.bandwidth,
    this.variants = const [],
  });

  @override
  String toString() {
    return 'AtmosStreamInfo(isDolbyDigitalPlus: $isDolbyDigitalPlus, hasJocMetadata: $hasJocMetadata, isAtmosCandidate: $isAtmosCandidate, codec: $codec, channels: $channels, variants: ${variants.length})';
  }
}

class HlsAudioVariant {
  final String uri;
  final String codec;
  final String channels;
  final int bandwidth;
  final bool isAtmos;
  final bool isDolby51;
  final bool isStereo;

  const HlsAudioVariant({
    required this.uri,
    required this.codec,
    required this.channels,
    required this.bandwidth,
    required this.isAtmos,
    required this.isDolby51,
    required this.isStereo,
  });
}

class HlsAtmosInspector {
  static AtmosStreamInfo inspect(String playlist) {
    final lines = playlist.split('\n');

    bool eac3 = false;
    bool joc = false;

    String codec = 'Unknown';
    String channels = 'Unknown';
    int? primaryBandwidth;
    final List<HlsAudioVariant> variants = [];

    String? pendingStreamInf;
    int? pendingBandwidth;
    String? pendingCodecs;
    String? pendingChannels;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Parse #EXT-X-STREAM-INF
      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        pendingStreamInf = line;

        final codecsMatch = RegExp(
          r'CODECS="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(line);

        final channelsMatch = RegExp(
          r'CHANNELS="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(line);

        final bandwidthMatch = RegExp(
          r'BANDWIDTH=(\d+)',
          caseSensitive: false,
        ).firstMatch(line);

        if (codecsMatch != null) {
          pendingCodecs = codecsMatch.group(1)!;
          if (pendingCodecs.toLowerCase().contains('ec-3') ||
              pendingCodecs.toLowerCase().contains('eac3') ||
              pendingCodecs.toLowerCase().contains('eac-3')) {
            eac3 = true;
          }
          if (codec == 'Unknown') {
            codec = pendingCodecs;
          }
        }

        if (channelsMatch != null) {
          pendingChannels = channelsMatch.group(1)!;
          if (pendingChannels.toUpperCase().contains('JOC')) {
            joc = true;
          }
          if (channels == 'Unknown') {
            channels = pendingChannels;
          }
        }

        if (bandwidthMatch != null) {
          pendingBandwidth = int.tryParse(bandwidthMatch.group(1)!);
          primaryBandwidth ??= pendingBandwidth;
        }
        continue;
      }

      // If previous line was #EXT-X-STREAM-INF, this non-comment line is the URI
      if (pendingStreamInf != null && !line.startsWith('#')) {
        final variantUri = line;
        final vCodec = pendingCodecs ?? 'Unknown';
        final vChannels = pendingChannels ?? 'Unknown';
        final vBandwidth = pendingBandwidth ?? 0;

        final isEac3Variant = vCodec.toLowerCase().contains('ec-3') ||
            vCodec.toLowerCase().contains('eac3') ||
            vCodec.toLowerCase().contains('eac-3');
        final isJocVariant = vChannels.toUpperCase().contains('JOC');
        final is51Variant = isEac3Variant && !isJocVariant;
        final isStereoVariant = vCodec.toLowerCase().contains('mp4a') ||
            vChannels == '2' ||
            vChannels == 'stereo';

        variants.add(HlsAudioVariant(
          uri: variantUri,
          codec: vCodec,
          channels: vChannels,
          bandwidth: vBandwidth,
          isAtmos: isEac3Variant && isJocVariant,
          isDolby51: is51Variant,
          isStereo: isStereoVariant,
        ));

        // Prioritize Atmos codec/channels info if found on any variant
        if (isEac3Variant && isJocVariant) {
          codec = vCodec;
          channels = vChannels;
          eac3 = true;
          joc = true;
        }

        pendingStreamInf = null;
        pendingBandwidth = null;
        pendingCodecs = null;
        pendingChannels = null;
        continue;
      }

      // Parse #EXT-X-MEDIA:TYPE=AUDIO
      if (line.startsWith('#EXT-X-MEDIA:') && line.contains('TYPE=AUDIO')) {
        final codecsMatch = RegExp(
          r'CODECS="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(line);

        final channelsMatch = RegExp(
          r'CHANNELS="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(line);

        final uriMatch = RegExp(
          r'URI="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(line);

        final groupIdMatch = RegExp(
          r'GROUP-ID="([^"]+)"',
          caseSensitive: false,
        ).firstMatch(line);

        final groupId = groupIdMatch?.group(1) ?? '';

        String mediaCodec = 'Unknown';
        String mediaChannels = 'Unknown';
        String mediaUri = '';

        if (codecsMatch != null) {
          mediaCodec = codecsMatch.group(1)!;
        } else if (groupId.toLowerCase().contains('ec-3') || groupId.toLowerCase().contains('ec3')) {
          mediaCodec = 'ec-3';
        } else if (groupId.toLowerCase().contains('aac')) {
          mediaCodec = 'mp4a.40.2';
        } else if (groupId.toLowerCase().contains('ac3') || groupId.toLowerCase().contains('ac-3')) {
          mediaCodec = 'ac-3';
        }

        if (channelsMatch != null) {
          mediaChannels = channelsMatch.group(1)!;
          if (mediaChannels.toUpperCase().contains('JOC')) {
            joc = true;
            if (mediaCodec == 'Unknown') mediaCodec = 'ec-3';
          }
        }

        if (mediaCodec.toLowerCase().contains('ec-3') ||
            mediaCodec.toLowerCase().contains('eac3') ||
            mediaCodec.toLowerCase().contains('eac-3') ||
            groupId.toLowerCase().contains('ec-3') ||
            groupId.toLowerCase().contains('ec3')) {
          eac3 = true;
        }

        if (uriMatch != null) {
          mediaUri = uriMatch.group(1)!;
        }

        final isEac3Media = mediaCodec.toLowerCase().contains('ec-3') ||
            mediaCodec.toLowerCase().contains('eac3') ||
            mediaCodec.toLowerCase().contains('eac-3') ||
            groupId.toLowerCase().contains('ec-3') ||
            groupId.toLowerCase().contains('ec3') ||
            mediaChannels.toUpperCase().contains('JOC');
        final isJocMedia = mediaChannels.toUpperCase().contains('JOC');

        if (isEac3Media && isJocMedia) {
          codec = mediaCodec;
          channels = mediaChannels;
          eac3 = true;
          joc = true;
        } else if (channels == 'Unknown' && channelsMatch != null) {
          channels = mediaChannels;
        }

        if (mediaUri.isNotEmpty) {
          variants.add(HlsAudioVariant(
            uri: mediaUri,
            codec: mediaCodec,
            channels: mediaChannels,
            bandwidth: 0,
            isAtmos: isEac3Media && isJocMedia,
            isDolby51: isEac3Media && !isJocMedia,
            isStereo: mediaCodec.toLowerCase().contains('mp4a') || mediaChannels == '2',
          ));
        }
      }
    }

    return AtmosStreamInfo(
      isDolbyDigitalPlus: eac3,
      hasJocMetadata: joc,
      isAtmosCandidate: eac3 && joc,
      codec: codec,
      channels: channels,
      bandwidth: primaryBandwidth,
      variants: variants,
    );
  }

  /// Selects the best audio variant according to the specification fallback hierarchy:
  /// 1. Dolby Atmos E-AC-3 JOC
  /// 2. Compatible Dolby 5.1
  /// 3. Stereo AAC
  /// 4. null (clear playback error)
  static HlsAudioVariant? selectFallbackVariant(List<HlsAudioVariant> variants) {
    if (variants.isEmpty) return null;

    // 1. Dolby Atmos E-AC-3 JOC
    for (final v in variants) {
      if (v.isAtmos) return v;
    }

    // 2. Compatible Dolby 5.1
    for (final v in variants) {
      if (v.isDolby51) return v;
    }

    // 3. Stereo AAC
    for (final v in variants) {
      if (v.isStereo) return v;
    }

    // Return first variant if none matched
    return variants.first;
  }
}
