// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord audio engine (Apache License 2.0).

/// Canonical PCM encodings supported across the audio processing and output pipeline.
enum PcmEncoding {
  pcm16(label: '16-bit Signed Integer PCM', bitsPerSample: 16),
  pcm24Packed(label: '24-bit Packed Integer PCM', bitsPerSample: 24),
  pcm32Int(label: '32-bit Signed Integer PCM', bitsPerSample: 32),
  pcmFloat32(label: '32-bit Normalized Float PCM', bitsPerSample: 32),
  dsdOverPcm(label: 'DSD over PCM (DoP v1.0)', bitsPerSample: 24);

  final String label;
  final int bitsPerSample;

  const PcmEncoding({
    required this.label,
    required this.bitsPerSample,
  });

  /// Bytes per single channel sample.
  int get bytesPerSample => (bitsPerSample + 7) ~/ 8;

  /// Bytes required for one interleaved multi-channel audio frame.
  int bytesPerFrame(int channelCount) => bytesPerSample * channelCount;

  bool get isFloat => this == PcmEncoding.pcmFloat32;
  bool get isDsd => this == PcmEncoding.dsdOverPcm;
}
