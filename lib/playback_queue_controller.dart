import 'dart:math';
import 'main.dart' show SongItem, RepeatMode;

/// Authoritative single source of truth for AuraBeat playback queue management.
class PlaybackQueueController {
  List<SongItem> _queue = [];
  int _queueIndex = 0;
  SongItem? _currentSong;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffle = false;
  List<int> _shuffledIndices = [];
  int _playGeneration = 0;

  PlaybackQueueController({List<SongItem>? initialQueue}) {
    if (initialQueue != null && initialQueue.isNotEmpty) {
      _queue = List<SongItem>.from(initialQueue);
      _currentSong = _queue.first;
      _queueIndex = 0;
    }
  }

  List<SongItem> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;
  SongItem? get currentSong => _currentSong;
  RepeatMode get repeatMode => _repeatMode;
  bool get isShuffle => _isShuffle;
  List<int> get shuffledIndices => List.unmodifiable(_shuffledIndices);
  int get playGeneration => _playGeneration;

  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
  }

  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    if (_isShuffle) {
      generateShuffleIndices();
    }
  }

  void setShuffle(bool shuffle) {
    _isShuffle = shuffle;
    if (_isShuffle) {
      generateShuffleIndices();
    }
  }

  void generateShuffleIndices({Random? random}) {
    if (_queue.isEmpty) {
      _shuffledIndices = [];
      return;
    }
    _shuffledIndices = List<int>.generate(_queue.length, (i) => i);
    final activeIdx = (_queueIndex >= 0 && _queueIndex < _queue.length) ? _queueIndex : 0;
    _shuffledIndices.remove(activeIdx);
    _shuffledIndices.shuffle(random);
    _shuffledIndices.insert(0, activeIdx);
  }

  /// Selects a song, updates queue if provided, and increments play generation.
  int selectSong(SongItem song, {List<SongItem>? newQueue, int? indexInQueue}) {
    _playGeneration++;

    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = List<SongItem>.from(newQueue);
      if (_isShuffle) {
        generateShuffleIndices();
      }
    }

    int targetIndex = indexInQueue ?? _queue.indexWhere((s) => s.id == song.id);
    if (targetIndex != -1) {
      _queueIndex = targetIndex;
    } else {
      _queue.add(song);
      _queueIndex = _queue.length - 1;
      if (_isShuffle) {
        _shuffledIndices.add(_queueIndex);
      }
    }

    _currentSong = song;
    return _playGeneration;
  }

  /// Calculates next track based on current queue, shuffle, and repeat modes.
  /// Returns the next SongItem, or null if the queue has ended and repeat is off.
  SongItem? getNextTrack({bool isAuto = false}) {
    if (_repeatMode == RepeatMode.one && isAuto) {
      return _currentSong;
    }

    if (_queue.isEmpty) return null;

    int nextIndex = -1;

    if (_isShuffle) {
      if (_shuffledIndices.isEmpty || _shuffledIndices.length != _queue.length) {
        generateShuffleIndices();
      }
      final curPos = _shuffledIndices.indexOf(_queueIndex);
      if (curPos != -1 && curPos + 1 < _shuffledIndices.length) {
        nextIndex = _shuffledIndices[curPos + 1];
      } else if (_repeatMode == RepeatMode.all) {
        generateShuffleIndices();
        nextIndex = _shuffledIndices.isNotEmpty ? _shuffledIndices.first : 0;
      }
    } else {
      final curIdx = _currentSong != null ? _queue.indexWhere((s) => s.id == _currentSong!.id) : -1;
      final activeIdx = curIdx != -1 ? curIdx : _queueIndex;

      if (activeIdx + 1 < _queue.length) {
        nextIndex = activeIdx + 1;
      } else if (_repeatMode == RepeatMode.all) {
        nextIndex = 0;
      }
    }

    if (nextIndex >= 0 && nextIndex < _queue.length) {
      _queueIndex = nextIndex;
      _currentSong = _queue[nextIndex];
      _playGeneration++;
      return _currentSong;
    }

    return null;
  }

  /// Calculates previous track based on current queue, shuffle, and repeat modes.
  SongItem? getPreviousTrack() {
    if (_queue.isEmpty) return null;

    int prevIndex = -1;

    if (_isShuffle) {
      if (_shuffledIndices.isEmpty || _shuffledIndices.length != _queue.length) {
        generateShuffleIndices();
      }
      final curPos = _shuffledIndices.indexOf(_queueIndex);
      if (curPos > 0) {
        prevIndex = _shuffledIndices[curPos - 1];
      } else if (_repeatMode == RepeatMode.all) {
        prevIndex = _shuffledIndices.isNotEmpty ? _shuffledIndices.last : 0;
      } else {
        prevIndex = _shuffledIndices.isNotEmpty ? _shuffledIndices.first : 0;
      }
    } else {
      final curIdx = _currentSong != null ? _queue.indexWhere((s) => s.id == _currentSong!.id) : -1;
      final activeIdx = curIdx != -1 ? curIdx : _queueIndex;

      if (activeIdx - 1 >= 0) {
        prevIndex = activeIdx - 1;
      } else if (_repeatMode == RepeatMode.all) {
        prevIndex = _queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }

    if (prevIndex >= 0 && prevIndex < _queue.length) {
      _queueIndex = prevIndex;
      _currentSong = _queue[prevIndex];
      _playGeneration++;
      return _currentSong;
    }

    return null;
  }
}
