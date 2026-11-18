import 'package:flutter/material.dart';

enum RecommendationSource {
  songSeed,
  artistSeed,
  albumSeed,
  genreSeed,
  moodSeed,
  tasteProfile,
  dailyMix,
  discoverWeekly,
  releaseRadar,
  searchQuery,
  radioStation,
  autoplay,
  deepCuts,
  hiddenGems,
}

class RecommendationItem {
  final dynamic song; // SongItem instance
  final double score;
  final String explanation;
  final RecommendationSource source;
  final Map<String, dynamic> metadata;

  const RecommendationItem({
    required this.song,
    required this.score,
    required this.explanation,
    required this.source,
    this.metadata = const {},
  });
}

class RadioStation {
  final String id;
  final String title;
  final String subtitle;
  final String coverUrl;
  final String seedType; // 'song', 'artist', 'album', 'genre', 'mood'
  final String seedId;
  final List<dynamic> queue; // List<SongItem>
  final Color accentColor;

  const RadioStation({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverUrl,
    required this.seedType,
    required this.seedId,
    required this.queue,
    this.accentColor = const Color(0xFFFEDBB3),
  });
}

class PersonalizedMix {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String badge;
  final Color accentColor;
  final List<dynamic> tracks; // List<SongItem>
  final String primaryGenre;

  const PersonalizedMix({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.badge,
    required this.accentColor,
    required this.tracks,
    required this.primaryGenre,
  });
}

class SearchRecommendationResult {
  final dynamic bestMatchSong;
  final dynamic bestMatchArtist;
  final dynamic bestMatchAlbum;
  final List<dynamic> matchingSongs;
  final List<dynamic> similarSongs;
  final List<dynamic> matchingArtists;
  final List<dynamic> similarArtists;
  final List<dynamic> matchingAlbums;
  final List<dynamic> relatedAlbums;
  final List<String> suggestedQueries;
  final List<RecommendationItem> recommendedForYou;
  final String detectedCategory; // 'song', 'artist', 'album', 'genre', 'mood', 'all'

  const SearchRecommendationResult({
    this.bestMatchSong,
    this.bestMatchArtist,
    this.bestMatchAlbum,
    required this.matchingSongs,
    required this.similarSongs,
    required this.matchingArtists,
    required this.similarArtists,
    required this.matchingAlbums,
    required this.relatedAlbums,
    required this.suggestedQueries,
    required this.recommendedForYou,
    required this.detectedCategory,
  });
}

class ListeningEvent {
  final String songId;
  final String artist;
  final String genre;
  final DateTime timestamp;
  final double durationSeconds;
  final double completionRatio; // 0.0 to 1.0
  final bool wasSkipped;
  final bool wasLiked;

  const ListeningEvent({
    required this.songId,
    required this.artist,
    required this.genre,
    required this.timestamp,
    required this.durationSeconds,
    required this.completionRatio,
    required this.wasSkipped,
    required this.wasLiked,
  });

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'artist': artist,
    'genre': genre,
    'timestamp': timestamp.toIso8601String(),
    'durationSeconds': durationSeconds,
    'completionRatio': completionRatio,
    'wasSkipped': wasSkipped,
    'wasLiked': wasLiked,
  };

  factory ListeningEvent.fromJson(Map<String, dynamic> json) => ListeningEvent(
    songId: json['songId'] as String,
    artist: json['artist'] as String,
    genre: json['genre'] as String? ?? 'General',
    timestamp: DateTime.parse(json['timestamp'] as String),
    durationSeconds: (json['durationSeconds'] as num).toDouble(),
    completionRatio: (json['completionRatio'] as num).toDouble(),
    wasSkipped: json['wasSkipped'] as bool? ?? false,
    wasLiked: json['wasLiked'] as bool? ?? false,
  );
}
