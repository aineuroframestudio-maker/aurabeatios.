// Copyright (C) 2026 AuraBeat Project.
// Adapted from BitChord Desktop audio engine (Thread-Isolated Lookahead Decode Ring Buffer).

import 'dart:collection';
import 'dart:typed_data';
import '../pcm/audio_block.dart';

/// Thread-safe lookahead FIFO buffer queue decoupling network range requests from audio playback.
///
/// Prevents buffer underruns and audio glitches caused by intermittent Wi-Fi/cellular latency
/// by buffering up to [aheadSeconds] (default 8s) of decoded PCM frames.
class DecodeAheadBuffer {
  static const int defaultAheadSeconds = 8;
  static const int starvedThresholdMs = 20;

  final int sampleRate;
  final int channels;
  final int aheadSeconds;
  final int aheadSamples;

  final Queue<Float32List> _queue = Queue<Float32List>();
  int _queuedSamples = 0;
  bool _ended = false;
  bool _closed = false;
  int _generation = 0;
  bool _started = false;
  int _starvationEvents = 0;

  DecodeAheadBuffer({
    this.sampleRate = 44100,
    this.channels = 2,
    this.aheadSeconds = defaultAheadSeconds,
  }) : aheadSamples = sampleRate * channels * aheadSeconds {
    assert(sampleRate > 0, 'sampleRate must be positive');
    assert(channels > 0, 'channels must be positive');
    assert(aheadSeconds > 0, 'aheadSeconds must be positive');
  }

  /// Current number of samples queued in the buffer.
  int get queuedSamples => _queuedSamples;

  /// Current duration in seconds buffered ahead of playback.
  double get bufferedSeconds => _queuedSamples / (sampleRate * channels);

  /// Whether the buffer has enough samples to satisfy [aheadSeconds].
  bool get isFull => _queuedSamples >= aheadSamples;

  /// Whether the buffer has reached the end of stream.
  bool get hasEnded => _ended;

  /// Whether the buffer has been closed.
  bool get isClosed => _closed;

  /// Number of starvation events (queue ran dry during playback).
  int get starvationEvents => _starvationEvents;

  /// Appends decoded PCM samples to the lookahead buffer.
  bool pushSamples(Float32List samples, {int? count, int? blockGeneration}) {
    if (_closed) return false;
    if (blockGeneration != null && blockGeneration != _generation) {
      // Discard block decoded from an old position before seek
      return false;
    }

    final n = count ?? samples.length;
    if (n <= 0) return true;

    final copy = Float32List(n);
    copy.setRange(0, n, samples);
    _queue.addLast(copy);
    _queuedSamples += n;
    return true;
  }

  /// Appends decoded [AudioBlock] samples.
  bool pushBlock(AudioBlock block, {int? blockGeneration}) {
    if (block.sampleCount <= 0) return true;
    return pushSamples(block.samples, count: block.sampleCount, blockGeneration: blockGeneration);
  }

  /// Marks that the source decoder has finished producing samples.
  void markEnded() {
    _ended = true;
  }

  /// Pops the next block of samples for the playback sink.
  Float32List? popSamples() {
    if (_closed) return null;
    if (_queue.isEmpty) {
      if (_started && !_ended) {
        _starvationEvents++;
      }
      return null;
    }

    final block = _queue.removeFirst();
    _queuedSamples -= block.length;
    _started = true;
    return block;
  }

  /// Seeks to a new position, immediately discarding previously buffered lookahead samples
  /// and bumping the generation counter.
  int seek() {
    _generation++;
    _queue.clear();
    _queuedSamples = 0;
    _ended = false;
    _started = false;
    return _generation;
  }

  /// Closes the buffer and discards all pending memory.
  void close() {
    _closed = true;
    _queue.clear();
    _queuedSamples = 0;
  }

  /// Resets the buffer state.
  void reset() {
    _closed = false;
    _ended = false;
    _started = false;
    _generation++;
    _queue.clear();
    _queuedSamples = 0;
  }
}
