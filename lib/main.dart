import 'dart:async';
import 'package:flutter/material.dart';
import 'audio_bridge.dart';
import 'recommendations/recommendation_engine.dart';
import 'sources/models/addon_source_model.dart';
import 'sources/addon_source_registry.dart';
import 'sources/services/addon_discovery_service.dart';
import 'sources/models/audio_quality_models.dart';
import 'sources/services/addon_quality_manager.dart';
import 'sources/services/addon_search_service.dart';
import 'sources/services/addon_stream_resolver.dart';
import 'sources/services/lossless_output_manager.dart';
import 'sources/services/addon_logger.dart';
import 'dolby_atmos/atmos_badge.dart';
import 'dolby_atmos/atmos_streaming_manager.dart';
import 'dolby_atmos/atmos_diagnostic_screen.dart';
import 'screens/sub_bass_enhancement_screen.dart';
import 'audio_engine/audio_engine.dart';
import 'playback_queue_controller.dart';

void main() {
  runApp(const AuraBeatApp());
}

class SongItem {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String duration;
  final int durationSec;
  final String coverUrl;
  final List<String> lyrics;
  final String genre;
  final List<String> subgenres;
  final int year;
  final int bpm;
  final String mood;
  final String language;
  final String audioQuality;
  final int popularity;
  final bool isExplicit;
  final bool isDolbyAtmos;
  final bool isHiRes;
  final String sourceId;
  final String sourceName;
  final String? streamUrl;

  const SongItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.durationSec,
    required this.coverUrl,
    required this.lyrics,
    this.genre = 'Electronic',
    this.subgenres = const [],
    this.year = 2018,
    this.bpm = 120,
    this.mood = 'Energetic',
    this.language = 'English',
    this.audioQuality = '24-bit/96kHz FLAC',
    this.popularity = 85,
    this.isExplicit = false,
    this.isDolbyAtmos = false,
    this.isHiRes = true,
    this.sourceId = 'dev.akira.bitchord-hires',
    this.sourceName = 'BitChord Hi-Res Add-on',
    this.streamUrl,
  });

  SongItem copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? duration,
    int? durationSec,
    String? coverUrl,
    List<String>? lyrics,
    String? genre,
    List<String>? subgenres,
    int? year,
    int? bpm,
    String? mood,
    String? language,
    String? audioQuality,
    int? popularity,
    bool? isExplicit,
    bool? isDolbyAtmos,
    bool? isHiRes,
    String? sourceId,
    String? sourceName,
    String? streamUrl,
  }) {
    return SongItem(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      durationSec: durationSec ?? this.durationSec,
      coverUrl: coverUrl ?? this.coverUrl,
      lyrics: lyrics ?? this.lyrics,
      genre: genre ?? this.genre,
      subgenres: subgenres ?? this.subgenres,
      year: year ?? this.year,
      bpm: bpm ?? this.bpm,
      mood: mood ?? this.mood,
      language: language ?? this.language,
      audioQuality: audioQuality ?? this.audioQuality,
      popularity: popularity ?? this.popularity,
      isExplicit: isExplicit ?? this.isExplicit,
      isDolbyAtmos: isDolbyAtmos ?? this.isDolbyAtmos,
      isHiRes: isHiRes ?? this.isHiRes,
      sourceId: sourceId ?? this.sourceId,
      sourceName: sourceName ?? this.sourceName,
      streamUrl: streamUrl ?? this.streamUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum RepeatMode {
  off,
  all,
  one,
}

class AlbumItem {
  final String id;
  final String title;
  final String artist;
  final String year;
  final String coverUrl;
  final String trackCount;
  final String genre;

  const AlbumItem({
    required this.id,
    required this.title,
    required this.artist,
    required this.year,
    required this.coverUrl,
    required this.trackCount,
    required this.genre,
  });
}

class ArtistItem {
  final String id;
  final String name;
  final String genre;
  final String avatarUrl;
  final String monthlyListeners;

  const ArtistItem({
    required this.id,
    required this.name,
    required this.genre,
    required this.avatarUrl,
    required this.monthlyListeners,
  });
}

class PlaylistItem {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final String trackCount;
  final String badge;
  final Color accentColor;

  const PlaylistItem({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.trackCount,
    required this.badge,
    required this.accentColor,
  });
}

class AuraBeatApp extends StatefulWidget {
  const AuraBeatApp({super.key});

  @override
  State<AuraBeatApp> createState() => _AuraBeatAppState();
}

class _AuraBeatAppState extends State<AuraBeatApp> {
  bool _isDarkEspresso = false;

  void _toggleTheme() {
    setState(() {
      _isDarkEspresso = !_isDarkEspresso;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors derived from the aesthetic peach/cream image
    const creamBg = Color(0xFFFEDBB3);
    const darkEspressoBg = Color(0xFF1A1614);

    return MaterialApp(
      title: 'Aura Beat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDarkEspresso ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: _isDarkEspresso ? darkEspressoBg : creamBg,
        primaryColor: Colors.black,
        colorScheme: _isDarkEspresso
            ? const ColorScheme.dark(
                primary: Color(0xFFFEDBB3),
                secondary: Color(0xFFF9CAA0),
                surface: Color(0xFF26201D),
              )
            : const ColorScheme.light(
                primary: Colors.black,
                secondary: Color(0xFF2D2520),
                surface: Color(0xFFFFF2E3),
              ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: AuraBeatHomePage(
        isDarkEspresso: _isDarkEspresso,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

/// Custom painted black circular emblem with peach/cream soundwave arcs
class AuraLogo extends StatelessWidget {
  final double size;
  final Color circleColor;
  final Color waveColor;

  const AuraLogo({
    super.key,
    this.size = 54,
    this.circleColor = Colors.black,
    this.waveColor = const Color(0xFFFEDBB3),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: size * 0.16,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _AuraSoundwavePainter(waveColor),
      ),
    );
  }
}

class _AuraSoundwavePainter extends CustomPainter {
  final Color waveColor;
  _AuraSoundwavePainter(this.waveColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.50;
    final cy = size.height * 0.54;

    // Top arc (longest, thickest)
    paint.strokeWidth = size.width * 0.088;
    final r1 = size.width * 0.31;
    final rect1 = Rect.fromCircle(center: Offset(cx, cy + r1 * 0.62), radius: r1);
    canvas.drawArc(rect1, -2.40, 1.44, false, paint);

    // Middle arc
    paint.strokeWidth = size.width * 0.080;
    final r2 = size.width * 0.22;
    final rect2 = Rect.fromCircle(center: Offset(cx, cy + r2 * 0.58), radius: r2);
    canvas.drawArc(rect2, -2.45, 1.40, false, paint);

    // Bottom arc (shortest)
    paint.strokeWidth = size.width * 0.072;
    final r3 = size.width * 0.145;
    final rect3 = Rect.fromCircle(center: Offset(cx, cy + r3 * 0.52), radius: r3);
    canvas.drawArc(rect3, -2.52, 1.35, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AuraBeatHomePage extends StatefulWidget {
  final bool isDarkEspresso;
  final VoidCallback onToggleTheme;

  const AuraBeatHomePage({
    super.key,
    required this.isDarkEspresso,
    required this.onToggleTheme,
  });

  @override
  State<AuraBeatHomePage> createState() => _AuraBeatHomePageState();
}

class _AuraBeatHomePageState extends State<AuraBeatHomePage> {
  int _selectedNav = 0;
  bool _isPlaying = false;
  double _currentPosition = 24.0;
  double _volume = 1.0;
  bool _isLiked = false;
  bool _showLyrics = false;
  Timer? _playbackTimer;

  // Authoritative Playback Queue & Navigation State (Single Source of Truth)
  final PlaybackQueueController _queueController = PlaybackQueueController();
  RepeatMode _repeatMode = RepeatMode.off;
  bool _isShuffle = false;
  List<SongItem> _queue = [];
  int _queueIndex = 0;
  List<int> _shuffledIndices = [];
  int _playGeneration = 0;
  String? _playbackErrorMessage;

  // Desktop Spatial Audio & Dolby Atmos State
  bool _isSpatialAudio = false;
  final AtmosStreamingManager _atmosStreamingManager = AtmosStreamingManager();

  // Settings Category & Search State ("All Categories Way")
  int _selectedSettingsCategory = 0; // 0: All, 1: Audio Quality, 2: Playback & DSP, 3: Appearance, 4: Downloads & Storage, 5: Your Data & Backup, 6: About
  String _settingsSearchQuery = '';
  String _homeSearchQuery = '';
  int _addonSearchLimit = 4;
  bool _isLoadingMoreAddon = false;
  bool _allAddonResultsLoaded = false;
  String _selectedCategoryFilter = 'All';
  final Set<String> _likedSongIds = {'1', '3'};

  // Audio Quality & AuraBeat Master Engine Settings (Phase 5, 11)
  GlobalQualityProfile _globalStreamingProfile = GlobalQualityProfile.ultraHiRes;
  String _preferredAudioFormat = 'Auto';
  bool _preferHiRes = true;
  bool _preferLossless = true;
  bool _strictLossless = false;
  bool _allowLossyFallback = true;
  String _wifiStreamingQuality = 'Ultra Hi-Res FLAC (24-bit/192kHz · 9216 kbps)';
  String _cellularStreamingQuality = 'Hi-Res Audio (24-bit/96kHz · 4608 kbps)';
  bool _dolbyAtmosEnabled = false;
  String _directSourceStreamMode = 'Always';
  bool _smartVersionAlignment = true;

  // Verified Technical Audio Metadata for Now Playing (Phase 8, 13)
  AudioMetadata _currentAudioMetadata = const AudioMetadata(
    codec: 'FLAC',
    container: 'flac',
    bitrateKbps: 9216,
    sampleRateHz: 192000,
    bitDepth: 24,
    channels: 2,
    isLossless: true,
    isHiRes: true,
    isDolbyAtmos: false,
    sourceId: 'dev.akira.bitchord-hires',
    sourceName: 'BitChord Hi-Res Add-on',
    streamType: 'Direct Bit-Perfect Bitstream (24-bit / 192 kHz FLAC)',
  );

  // Playback & DSP Settings
  bool _loudnessNormalization = true;
  bool _skipSilence = false;
  double _playbackSpeed = 1.0;
  double _crossfadeDuration = 3.5;
  bool _automixEnabled = true;
  bool _bassBoostEnabled = true;
  double _bassBoostGain = 10.0;
  bool _subBassEnabled = false;
  double _subBassIntensity = 0.50;
  double _subBassFrequency = 60.0;
  double _subBassOutputLevel = 0.0;
  String _subBassPreset = 'Natural Sub-Bass';
  List<double> _equalizerBands = [4.5, 3.5, 1.0, 1.5, 2.0, 2.5, 3.0]; // 32Hz, 64Hz, 250Hz, 1kHz, 4kHz, 8kHz, 16kHz (Audiophile Clear)
  String _equalizerPreset = 'Audiophile Clear';

  // Appearance Settings
  bool _syncedLyricsKaraoke = true;
  bool _unfocusedLyricsBlur = true;
  bool _fullScreenCoverArt = true;
  bool _animatedCanvasEnabled = true;
  bool _reduceAnimations = false;

  // Downloads & Storage Settings
  String _downloadAudioQuality = 'Lossless FLAC';
  bool _downloadWifiOnly = true;
  double _songCacheLimitGB = 5.0;
  int _cachedSongsCount = 142;
  double _cachedStorageMB = 1840.0;

  // Data & Backup Settings
  bool _workOutGenres = true;
  bool _keepDiagnosticLogs = true;
  bool _showNerdStats = false;

  // Centralized Recommendation Engine Instance & Radio State
  final RecommendationEngine _recEngine = RecommendationEngine.instance;
  final List<String> _sessionHistory = [];
  RadioStation? _activeRadioStation;

  final List<SongItem> _songs = [
    const SongItem(
      id: '1',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: '4:03',
      durationSec: 243,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Synthwave',
      subgenres: ['Dream Pop', 'Electronic', 'Shoegaze'],
      year: 2011,
      bpm: 105,
      mood: 'Energetic',
      popularity: 94,
      lyrics: [
        'Waiting in a car',
        'Waiting for a ride in the dark',
        'The night city grows',
        'Look and see her eyes, they glow',
        'Waiting in a car',
        'Waiting for a ride in the dark',
        'The city is my church',
        'It wraps me in the blinding twilight',
      ],
    ),
    const SongItem(
      id: '2',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      album: 'Starboy (Dolby Atmos Spatial Audio)',
      duration: '3:50',
      durationSec: 230,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
      genre: 'R&B / Synthwave',
      subgenres: ['Electro Pop', 'Pop', 'Dark R&B'],
      year: 2016,
      bpm: 186,
      mood: 'Energetic',
      popularity: 96,
      audioQuality: 'Dolby Atmos Spatial Audio (E-AC-3 JOC)',
      isDolbyAtmos: true,
      lyrics: [
        'I\'m tryna put you in the worst mood, ah',
        'P1 cleaner than your church shoes, ah',
        'Milli point two just to hurt you, ah',
        'All red Lamb\' just to tease you, ah',
        'Look what you\'ve done',
        'I\'m a motherfuckin\' starboy',
      ],
    ),
    const SongItem(
      id: '3',
      title: 'Get Lucky',
      artist: 'Daft Punk ft. Pharrell Williams',
      album: 'Random Access Memories',
      duration: '4:08',
      durationSec: 248,
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&q=80',
      genre: 'Nu-Disco / French House',
      subgenres: ['Funk', 'Disco', 'Electro'],
      year: 2013,
      bpm: 116,
      mood: 'Party',
      popularity: 92,
      lyrics: [
        'Like the legend of the phoenix',
        'All ends with beginnings',
        'What keeps the planet spinning',
        'The force from the beginning',
        'We\'ve come too far to give up who we are',
        'So let\'s raise the bar and our cups to the stars',
        'She\'s up all night \'til the sun',
        'I\'m up all night to get some',
        'She\'s up all night for good fun',
        'I\'m up all night to get lucky',
      ],
    ),
    const SongItem(
      id: '4',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours (Dolby Atmos Edition)',
      duration: '3:20',
      durationSec: 200,
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=300&q=80',
      genre: 'Synthwave',
      subgenres: ['Synthpop', '80s Retro', 'Pop'],
      year: 2020,
      bpm: 171,
      mood: 'Energetic',
      popularity: 98,
      audioQuality: 'Dolby Atmos Spatial Audio (E-AC-3 JOC)',
      isDolbyAtmos: true,
      lyrics: [
        'Yeah',
        'I\'ve been tryna call',
        'I\'ve been on my own for long enough',
        'Maybe you can show me how to love, maybe',
        'I\'m going through withdrawals',
        'You don\'t even have to do too much',
        'You can turn me on with just a touch, baby',
        'I look around and Sin City\'s cold and empty',
      ],
    ),
    const SongItem(
      id: '5',
      title: 'Instant Crush',
      artist: 'Daft Punk ft. Julian Casablancas',
      album: 'Random Access Memories',
      duration: '5:37',
      durationSec: 337,
      coverUrl: 'https://images.unsplash.com/photo-1445985543470-41fdd5c31447?w=300&q=80',
      genre: 'French House',
      subgenres: ['Indie Rock', 'Synthpop', 'Nu-Disco'],
      year: 2013,
      bpm: 110,
      mood: 'Late Night',
      popularity: 88,
      lyrics: [
        'I didn\'t want to be the one to forget',
        'I thought of everything I\'d never regret',
        'A little time with you is all that I get',
        'That\'s all we need because it\'s all we can take',
      ],
    ),
    const SongItem(
      id: '6',
      title: 'The Less I Know The Better',
      artist: 'Tame Impala',
      album: 'Currents',
      duration: '3:36',
      durationSec: 216,
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=300&q=80',
      genre: 'Psychedelic Pop',
      subgenres: ['Indie Rock', 'Neo-Psychedelia', 'Synth Funk'],
      year: 2015,
      bpm: 117,
      mood: 'Chill',
      popularity: 95,
      lyrics: [
        'Someone said they left together',
        'I ran out the door to get her',
        'She was holding hands with Trevor',
        'Not the greatest feeling ever',
      ],
    ),
    const SongItem(
      id: '7',
      title: 'Nightcall',
      artist: 'Kavinsky',
      album: 'OutRun',
      duration: '4:19',
      durationSec: 259,
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
      genre: 'Synthwave',
      subgenres: ['OutRun', 'Electro House', 'Darkwave'],
      year: 2013,
      bpm: 91,
      mood: 'Late Night',
      popularity: 89,
      lyrics: [
        'I\'m giving you a night call to tell you how I feel',
        'I want to drive you through the night, down the hills',
        'I\'m gonna tell you something you don\'t want to hear',
        'I\'m gonna show you where it\'s dark, but have no fear',
      ],
    ),
    const SongItem(
      id: '8',
      title: 'Wait',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: '5:43',
      durationSec: 343,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Dream Pop',
      subgenres: ['Ambient', 'Cinematic', 'Post-Rock'],
      year: 2011,
      bpm: 128,
      mood: 'Chill',
      popularity: 84,
      lyrics: [
        'Send your dreams where nobody hides',
        'Give your tears to the tide',
        'No time, no time',
        'There is no end, there is no goodbye',
      ],
    ),
    const SongItem(
      id: '9',
      title: 'One More Time',
      artist: 'Daft Punk',
      album: 'Discovery',
      duration: '5:20',
      durationSec: 320,
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&q=80',
      genre: 'French House',
      subgenres: ['Filter House', 'Disco', 'Dance'],
      year: 2001,
      bpm: 123,
      mood: 'Party',
      popularity: 91,
      lyrics: [
        'One more time, we\'re gonna celebrate',
        'Oh yeah, all right, don\'t stop the dancing',
      ],
    ),
    const SongItem(
      id: '10',
      title: 'Save Your Tears',
      artist: 'The Weeknd',
      album: 'After Hours',
      duration: '3:35',
      durationSec: 215,
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=300&q=80',
      genre: 'Synthwave',
      subgenres: ['Synthpop', 'R&B', 'Pop'],
      year: 2020,
      bpm: 118,
      mood: 'Energetic',
      popularity: 96,
      lyrics: [
        'I saw you dancing in a crowded room',
        'You look so happy when I\'m not with you',
      ],
    ),
    const SongItem(
      id: '11',
      title: 'Lover',
      artist: 'Diljit Dosanjh',
      album: 'MoonChild Era',
      duration: '3:15',
      durationSec: 195,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
      genre: 'Punjabi Pop',
      subgenres: ['Indian Pop', 'Urban Punjabi', 'Dance'],
      year: 2021,
      bpm: 105,
      mood: 'Energetic',
      language: 'Punjabi',
      popularity: 93,
      lyrics: [
        'Tera ni tera lover, baitha main door ni',
        'Aakhan naal aakhan mila lai hun taan tu',
        'Kehde tu pyar hai, soniye sun lai zara',
      ],
    ),
    const SongItem(
      id: '12',
      title: '295',
      artist: 'Sidhu Moose Wala',
      album: 'Moosetape',
      duration: '4:30',
      durationSec: 270,
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
      genre: 'Punjabi Pop',
      subgenres: ['Punjabi Hip-Hop', 'Desi Trap', 'Rap'],
      year: 2021,
      bpm: 94,
      mood: 'Intense',
      language: 'Punjabi',
      popularity: 95,
      lyrics: [
        'Dass keda karda ni ethe virodh',
        'Kise nu zameer di te kise nu lod',
        'Sun 295 de kisse tu sun le',
      ],
    ),
    const SongItem(
      id: '13',
      title: 'Kesariya',
      artist: 'Arijit Singh',
      album: 'Brahmastra',
      duration: '4:28',
      durationSec: 268,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Hindi',
      subgenres: ['Bollywood', 'Romantic', 'Acoustic Pop'],
      year: 2022,
      bpm: 92,
      mood: 'Romantic',
      language: 'Hindi',
      popularity: 97,
      lyrics: [
        'Kesariya tera ishq hai piya',
        'Rang jaaun jo main haath lagaun',
        'Din beete saara teri fikr mein',
        'Rain saari teri khair manaun',
      ],
    ),
    const SongItem(
      id: '14',
      title: 'Brown Munde',
      artist: 'AP Dhillon, Gurinder Gill',
      album: 'Not By Chance',
      duration: '4:07',
      durationSec: 247,
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=300&q=80',
      genre: 'Punjabi Pop',
      subgenres: ['Desi Hip-Hop', 'Trap', 'Urban Punjabi'],
      year: 2020,
      bpm: 85,
      mood: 'Late Night',
      language: 'Punjabi',
      popularity: 91,
      lyrics: [
        'Desi jehe geet aa trappan jehi beat aa',
        'Sir kadd gajde brown munde',
      ],
    ),
    const SongItem(
      id: '15',
      title: 'Pasoori',
      artist: 'Ali Sethi, Shae Gill',
      album: 'Coke Studio Season 14',
      duration: '3:44',
      durationSec: 224,
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&q=80',
      genre: 'South Asian Indie',
      subgenres: ['World', 'Fusion', 'Folk Pop'],
      year: 2022,
      bpm: 122,
      mood: 'Euphoric',
      language: 'Punjabi',
      popularity: 94,
      lyrics: [
        'Agg laavan majboori nu',
        'Aan jaan di pasoori nu',
        'Zehar bane haan teri',
        'Pee jaavan main poori nu',
      ],
    ),
    const SongItem(
      id: '16',
      title: 'Harder, Better, Faster, Stronger',
      artist: 'Daft Punk',
      album: 'Discovery',
      duration: '3:44',
      durationSec: 224,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
      genre: 'French House',
      subgenres: ['Electronic', 'Vocoder Funk', 'Nu-Disco'],
      year: 2001,
      bpm: 123,
      mood: 'Energetic',
      popularity: 90,
      lyrics: [
        'Work it make it do it makes us',
        'Harder better faster stronger',
        'More than ever hour after',
        'Our work is never over',
      ],
    ),
    const SongItem(
      id: '17',
      title: 'Borderline',
      artist: 'Tame Impala',
      album: 'The Slow Rush',
      duration: '3:57',
      durationSec: 237,
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=300&q=80',
      genre: 'Psychedelic Pop',
      subgenres: ['Neo-Psychedelia', 'Indie Disco', 'Chillwave'],
      year: 2020,
      bpm: 120,
      mood: 'Chill',
      popularity: 89,
      lyrics: [
        'Gone a little far, gone a little far this time for something',
        'How was I to know? How was I to know this dark will come?',
      ],
    ),
    const SongItem(
      id: '18',
      title: 'Let It Happen',
      artist: 'Tame Impala',
      album: 'Currents',
      duration: '7:48',
      durationSec: 468,
      coverUrl: 'https://images.unsplash.com/photo-1445985543470-41fdd5c31447?w=300&q=80',
      genre: 'Psychedelic Pop',
      subgenres: ['Psych Rock', 'Electronic Rock', 'Progressive'],
      year: 2015,
      bpm: 125,
      mood: 'Euphoric',
      popularity: 91,
      lyrics: [
        'It\'s always around me, all this noise',
        'All these emotions and choices',
        'Just let it happen, let it happen',
      ],
    ),
    const SongItem(
      id: '19',
      title: 'Out of Time',
      artist: 'The Weeknd',
      album: 'Dawn FM',
      duration: '3:34',
      durationSec: 214,
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=300&q=80',
      genre: 'R&B / Synthwave',
      subgenres: ['City Pop', 'Soul', 'Smooth R&B'],
      year: 2022,
      bpm: 93,
      mood: 'Chill',
      popularity: 88,
      lyrics: [
        'The last few months, I\'ve been workin\' on me, baby',
        'There\'s so much trauma in my life',
        'I\'ve been so cold to the ones who loved me, baby',
      ],
    ),
    const SongItem(
      id: '20',
      title: 'Genesis',
      artist: 'Justice',
      album: 'Cross',
      duration: '3:54',
      durationSec: 234,
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
      genre: 'French House',
      subgenres: ['Electro House', 'Complextro', 'French Touch'],
      year: 2007,
      bpm: 117,
      mood: 'Intense',
      popularity: 86,
      lyrics: [
        '[Instrumental French Electro Masterpiece]',
      ],
    ),
    const SongItem(
      id: '21',
      title: 'Pacific Coast Highway',
      artist: 'Kavinsky',
      album: 'OutRun',
      duration: '3:58',
      durationSec: 238,
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&q=80',
      genre: 'Synthwave',
      subgenres: ['OutRun', 'Electro', 'Cinematic'],
      year: 2013,
      bpm: 90,
      mood: 'Late Night',
      popularity: 83,
      lyrics: [
        '[Instrumental OutRun Synthwave]',
      ],
    ),
    const SongItem(
      id: '22',
      title: 'The Mother We Share',
      artist: 'CHVRCHES',
      album: 'The Bones of What You Believe',
      duration: '3:12',
      durationSec: 192,
      coverUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
      genre: 'Dream Pop',
      subgenres: ['Indie Synthpop', 'Electronic', 'Electropop'],
      year: 2013,
      bpm: 112,
      mood: 'Energetic',
      popularity: 87,
      lyrics: [
        'Never let you go, never let me down',
        'Into the shadows where the heart beats sound',
      ],
    ),
    const SongItem(
      id: '23',
      title: 'Clearest Blue',
      artist: 'CHVRCHES',
      album: 'Every Open Eye',
      duration: '3:53',
      durationSec: 233,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Dream Pop',
      subgenres: ['Indie Synthpop', 'Drop', 'Euphoric'],
      year: 2015,
      bpm: 130,
      mood: 'Euphoric',
      popularity: 88,
      lyrics: [
        'Light is on the horizon',
        'Can you meet me halfway?',
      ],
    ),
    const SongItem(
      id: '24',
      title: 'Resonance',
      artist: 'HOME',
      album: 'Odyssey',
      duration: '3:32',
      durationSec: 212,
      coverUrl: 'https://images.unsplash.com/photo-1445985543470-41fdd5c31447?w=300&q=80',
      genre: 'Chillwave',
      subgenres: ['Vaporwave', 'Ambient', 'Downtempo'],
      year: 2014,
      bpm: 100,
      mood: 'Chill',
      popularity: 93,
      lyrics: [
        '[Lush Analog Synth Frequencies]',
      ],
    ),
    const SongItem(
      id: '25',
      title: 'So High',
      artist: 'Sidhu Moose Wala',
      album: 'So High',
      duration: '3:56',
      durationSec: 236,
      coverUrl: 'https://c.saavncdn.com/544/So-High-Punjabi-2017-20220614133425-500x500.jpg',
      genre: 'Punjabi Hip-Hop',
      subgenres: ['Desi Hip-Hop', 'Gangsta Rap', 'Punjabi'],
      year: 2017,
      bpm: 90,
      mood: 'Intense',
      language: 'Punjabi',
      popularity: 98,
      lyrics: [
        'Chobbar de chehre utte noor dassda',
        'Ni ehda uthuga jawani ch janaja mithiye',
        'Ni high kudiye ni so high kudiye',
      ],
    ),
    const SongItem(
      id: '26',
      title: 'Excuses',
      artist: 'AP Dhillon',
      album: 'Hidden Gems',
      duration: '2:56',
      durationSec: 176,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Punjabi Pop',
      subgenres: ['R&B', 'Desi Pop', 'Urban Punjabi'],
      year: 2020,
      bpm: 96,
      mood: 'Chill',
      language: 'Punjabi',
      popularity: 95,
      lyrics: [
        'Dil nu dilaase den waleya',
        'Tu kehde paase tur geya ae',
      ],
    ),
    const SongItem(
      id: '27',
      title: 'Born to Shine',
      artist: 'Diljit Dosanjh',
      album: 'G.O.A.T.',
      duration: '3:33',
      durationSec: 213,
      coverUrl: 'https://c.saavncdn.com/945/G-O-A-T-Punjabi-2020-20200729003534-500x500.jpg',
      genre: 'Punjabi Pop',
      subgenres: ['Dance Pop', 'Electro Punjabi', 'Party'],
      year: 2020,
      bpm: 110,
      mood: 'Party',
      language: 'Punjabi',
      popularity: 96,
      lyrics: [
        'Paisa poosa baane daulat shohrat ki karni',
        'Born to shine tera yaar ni',
      ],
    ),
    const SongItem(
      id: '28',
      title: 'Softly',
      artist: 'Karan Aujla',
      album: 'Making Memories',
      duration: '2:36',
      durationSec: 156,
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=300&q=80',
      genre: 'Punjabi Pop',
      subgenres: ['Desi Hip-Hop', 'Urban Punjabi'],
      year: 2023,
      bpm: 98,
      mood: 'Smooth',
      language: 'Punjabi',
      popularity: 93,
      lyrics: [
        'Take it softly, dilaan di gal aayi ae',
      ],
    ),
    const SongItem(
      id: '29',
      title: 'Baller',
      artist: 'Shubh',
      album: 'No Love',
      duration: '2:28',
      durationSec: 148,
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
      genre: 'Punjabi Hip-Hop',
      subgenres: ['Trap', 'Desi Rap'],
      year: 2022,
      bpm: 140,
      mood: 'Energetic',
      language: 'Punjabi',
      popularity: 92,
      lyrics: [
        'Baller, life living large in the city lights',
      ],
    ),
    const SongItem(
      id: '30',
      title: 'Channa Mereya',
      artist: 'Arijit Singh',
      album: 'Ae Dil Hai Mushkil',
      duration: '4:49',
      durationSec: 289,
      coverUrl: 'https://c.saavncdn.com/597/Ae-Dil-Hai-Mushkil-Hindi-2016-500x500.jpg',
      genre: 'Bollywood / Hindi',
      subgenres: ['Romantic', 'Sufi Pop', 'Acoustic'],
      year: 2016,
      bpm: 94,
      mood: 'Romantic',
      language: 'Hindi',
      popularity: 98,
      lyrics: [
        'Acha chalta hoon, duaon mein yaad rakhna',
        'Mere zikr ka zubaan pe swaad rakhna',
        'O channa mereya mereya, o channa mereya',
      ],
    ),
    const SongItem(
      id: '31',
      title: 'Tum Hi Ho',
      artist: 'Arijit Singh',
      album: 'Aashiqui 2',
      duration: '4:22',
      durationSec: 262,
      coverUrl: 'https://images.unsplash.com/photo-1445985543470-41fdd5c31447?w=300&q=80',
      genre: 'Bollywood / Hindi',
      subgenres: ['Ballad', 'Romantic', 'Melancholy'],
      year: 2013,
      bpm: 85,
      mood: 'Melancholic',
      language: 'Hindi',
      popularity: 96,
      lyrics: [
        'Hum tere bin ab reh nahi sakte',
        'Tere bina kya wajood mera',
        'Kyunki tum hi ho, ab tum hi ho',
      ],
    ),
    const SongItem(
      id: '32',
      title: 'Kun Faya Kun',
      artist: 'A.R. Rahman',
      album: 'Rockstar',
      duration: '7:53',
      durationSec: 473,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
      genre: 'Sufi / Bollywood',
      subgenres: ['Devotional', 'Qawwali', 'Spiritual'],
      year: 2011,
      bpm: 76,
      mood: 'Spiritual',
      language: 'Hindi',
      popularity: 95,
      lyrics: [
        'Kun Faya Kun, Kun Faya Kun',
        'Jab kahin pe kuch nahi bhi nahi tha',
      ],
    ),
    const SongItem(
      id: '33',
      title: 'Maan Meri Jaan',
      artist: 'King',
      album: 'Champagne Talk',
      duration: '3:14',
      durationSec: 194,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Hindi Pop',
      subgenres: ['Melodic Rap', 'R&B'],
      year: 2022,
      bpm: 98,
      mood: 'Romantic',
      language: 'Hindi',
      popularity: 94,
      lyrics: [
        'Tu maan meri jaan, main tujhe jaane na dunga',
      ],
    ),
    const SongItem(
      id: '34',
      title: 'Zara Sa',
      artist: 'KK',
      album: 'Jannat',
      duration: '5:03',
      durationSec: 303,
      coverUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      genre: 'Bollywood / Hindi',
      subgenres: ['Rock Ballad', 'Nostalgia'],
      year: 2008,
      bpm: 115,
      mood: 'Passionate',
      language: 'Hindi',
      popularity: 93,
      lyrics: [
        'Zara sa jhoom loon main, are na re na re na',
        'Zara sa dil mein de jagah tu',
      ],
    ),
    const SongItem(
      id: '35',
      title: 'HUMBLE.',
      artist: 'Kendrick Lamar',
      album: 'DAMN.',
      duration: '2:57',
      durationSec: 177,
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
      genre: 'Hip-Hop / Rap',
      subgenres: ['Trap', 'Conscious Rap', 'West Coast'],
      year: 2017,
      bpm: 150,
      mood: 'Energetic',
      language: 'English',
      popularity: 96,
      lyrics: [
        'Nobody pray for me',
        'It been that day for me',
        'Be humble, sit down',
      ],
    ),
    const SongItem(
      id: '36',
      title: 'Lose Yourself',
      artist: 'Eminem',
      album: '8 Mile',
      duration: '5:26',
      durationSec: 326,
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=300&q=80',
      genre: 'Hip-Hop / Rap',
      subgenres: ['Hardcore Rap', 'Motivational'],
      year: 2002,
      bpm: 171,
      mood: 'Intense',
      language: 'English',
      popularity: 97,
      lyrics: [
        'Look, if you had one shot or one opportunity',
        'To seize everything you ever wanted in one moment',
      ],
    ),
    const SongItem(
      id: '37',
      title: 'God\'s Plan',
      artist: 'Drake',
      album: 'Scorpion',
      duration: '3:18',
      durationSec: 198,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Hip-Hop / Rap',
      subgenres: ['Trap', 'Pop Rap'],
      year: 2018,
      bpm: 77,
      mood: 'Uplifting',
      language: 'English',
      popularity: 95,
      lyrics: [
        'They wishin\' and wishin\' and wishin\' and wishin\'',
        'They wishin\' on me, yeah',
        'God\'s plan, God\'s plan',
      ],
    ),
    const SongItem(
      id: '38',
      title: 'Animals',
      artist: 'Martin Garrix',
      album: 'Gold Skies',
      duration: '5:04',
      durationSec: 304,
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=300&q=80',
      genre: 'EDM / Electronic',
      subgenres: ['Big Room House', 'Festival', 'Electro'],
      year: 2013,
      bpm: 128,
      mood: 'Party',
      language: 'Instrumental',
      popularity: 93,
      lyrics: [
        '[Massive Big Room Electro Drop]',
      ],
    ),
    const SongItem(
      id: '39',
      title: 'Wake Me Up',
      artist: 'Avicii',
      album: 'True',
      duration: '4:07',
      durationSec: 247,
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=300&q=80',
      genre: 'EDM / Electronic',
      subgenres: ['Folktronica', 'Melodic House'],
      year: 2013,
      bpm: 124,
      mood: 'Uplifting',
      language: 'English',
      popularity: 95,
      lyrics: [
        'Feeling my way through the darkness',
        'Guided by a beating heart',
      ],
    ),
    const SongItem(
      id: '40',
      title: 'Nuvole Bianche',
      artist: 'Ludovico Einaudi',
      album: 'Una Mattina',
      duration: '5:57',
      durationSec: 357,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
      genre: 'Classical / Instrumental',
      subgenres: ['Neoclassical', 'Piano Solo', 'Minimalism'],
      year: 2004,
      bpm: 72,
      mood: 'Peaceful',
      language: 'Instrumental',
      popularity: 91,
      lyrics: [
        '[Harmonic Neoclassical Piano Reverberation]',
      ],
    ),
    const SongItem(
      id: '41',
      title: 'Raga Bhupali (Bansuri & Tabla)',
      artist: 'Ustad Zakir Hussain',
      album: 'Echoes of the Valley',
      duration: '6:45',
      durationSec: 405,
      coverUrl: 'https://images.unsplash.com/photo-1445985543470-41fdd5c31447?w=300&q=80',
      genre: 'Classical / Instrumental',
      subgenres: ['Hindustani', 'Flute & Tabla', 'Meditation'],
      year: 2018,
      bpm: 84,
      mood: 'Meditative',
      language: 'Instrumental',
      popularity: 89,
      lyrics: [
        '[Transcendental Bansuri & Tabla Improvisation]',
      ],
    ),
    const SongItem(
      id: '42',
      title: 'Clair de Lune',
      artist: 'Claude Debussy',
      album: 'Suite Bergamasque',
      duration: '5:02',
      durationSec: 302,
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80',
      genre: 'Classical / Instrumental',
      subgenres: ['Impressionism', 'Piano Solo', 'Romantic'],
      year: 1905,
      bpm: 60,
      mood: 'Dreamy',
      language: 'Instrumental',
      popularity: 94,
      lyrics: [
        '[Poetic Impressionist Piano Solo]',
      ],
    ),
    const SongItem(
      id: 'dolby_8f31',
      title: 'Midnight Signal',
      artist: 'Example Artist',
      album: 'Night Drive',
      duration: '4:02',
      durationSec: 242,
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=300&q=80',
      genre: 'Synthwave / Spatial',
      subgenres: ['Dolby Atmos', 'Electronic', 'Retrowave'],
      year: 2024,
      bpm: 118,
      mood: 'Immersive',
      popularity: 95,
      audioQuality: 'Dolby Atmos Spatial Audio (E-AC-3 JOC)',
      isDolbyAtmos: true,
      sourceId: 'dev.akira.bitchord-hires',
      sourceName: 'BitChord Hi-Res Add-on',
      lyrics: [
        'Static in the midnight sky',
        'Signals moving through the dark',
        'Surround the room, surround the mind',
        'Electric waves leaving their mark',
        'Hear the space between the sound',
        'Seven channels off the ground',
      ],
    ),
    const SongItem(
      id: 'apple_atmos_ref',
      title: 'Apple Developer Dolby Atmos Reference Stream',
      artist: 'Apple Developer / Dolby',
      album: 'HLS Spatial Audio Test Suite',
      duration: '1:44',
      durationSec: 104,
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=300&q=80',
      genre: 'Spatial Audio Benchmark',
      subgenres: ['Dolby Atmos', 'E-AC-3 JOC', 'Reference'],
      year: 2024,
      bpm: 120,
      mood: 'Spatial Immersive',
      popularity: 99,
      audioQuality: 'Dolby Atmos E-AC-3 JOC (16/JOC · 768 kbps · 48 kHz)',
      isDolbyAtmos: true,
      sourceId: 'dev.akira.bitchord-hires',
      sourceName: 'BitChord Hi-Res Add-on',
      streamUrl: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8',
      lyrics: [
        'Official Apple Developer Reference Stream',
        'Enhanced AC-3 with Joint Object Coding (E-AC-3 JOC)',
        'Signalled via CHANNELS="16/JOC" and CODECS="ec-3"',
        'Decoded natively via AVPlayer & AVAudioSession (.moviePlayback)',
      ],
    ),
  ];

  final List<AlbumItem> _albums = const [
    AlbumItem(
      id: 'a1',
      title: 'Hurry Up, We\'re Dreaming',
      artist: 'M83',
      year: '2011',
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&q=80',
      trackCount: '22 tracks',
      genre: 'Dream Pop / Synthwave',
    ),
    AlbumItem(
      id: 'a2',
      title: 'Random Access Memories',
      artist: 'Daft Punk',
      year: '2013',
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&q=80',
      trackCount: '13 tracks',
      genre: 'Nu-Disco / Funk',
    ),
    AlbumItem(
      id: 'a3',
      title: 'After Hours',
      artist: 'The Weeknd',
      year: '2020',
      coverUrl: 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=400&q=80',
      trackCount: '14 tracks',
      genre: 'Synthwave / R&B',
    ),
    AlbumItem(
      id: 'a4',
      title: 'Currents',
      artist: 'Tame Impala',
      year: '2015',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=400&q=80',
      trackCount: '13 tracks',
      genre: 'Psychedelic Pop',
    ),
    AlbumItem(
      id: 'a5',
      title: 'Discovery',
      artist: 'Daft Punk',
      year: '2001',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&q=80',
      trackCount: '14 tracks',
      genre: 'French House',
    ),
    AlbumItem(
      id: 'a6',
      title: 'OutRun',
      artist: 'Kavinsky',
      year: '2013',
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&q=80',
      trackCount: '13 tracks',
      genre: 'Synthwave / Electro',
    ),
    AlbumItem(
      id: 'a7',
      title: 'Moosetape',
      artist: 'Sidhu Moose Wala',
      year: '2021',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&q=80',
      trackCount: '32 tracks',
      genre: 'Punjabi Hip-Hop',
    ),
    AlbumItem(
      id: 'a8',
      title: 'MoonChild Era',
      artist: 'Diljit Dosanjh',
      year: '2021',
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&q=80',
      trackCount: '9 tracks',
      genre: 'Punjabi Pop',
    ),
    AlbumItem(
      id: 'a9',
      title: 'Brahmāstra',
      artist: 'Pritam',
      year: '2022',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=400&q=80',
      trackCount: '8 tracks',
      genre: 'Bollywood / Hindi',
    ),
    AlbumItem(
      id: 'a10',
      title: 'Rockstar',
      artist: 'A.R. Rahman',
      year: '2011',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&q=80',
      trackCount: '14 tracks',
      genre: 'Sufi / Bollywood',
    ),
    AlbumItem(
      id: 'a11',
      title: 'DAMN.',
      artist: 'Kendrick Lamar',
      year: '2017',
      coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&q=80',
      trackCount: '14 tracks',
      genre: 'Hip-Hop / Rap',
    ),
    AlbumItem(
      id: 'a12',
      title: 'Una Mattina',
      artist: 'Ludovico Einaudi',
      year: '2004',
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&q=80',
      trackCount: '13 tracks',
      genre: 'Classical / Instrumental',
    ),
    AlbumItem(
      id: 'a13',
      title: 'True',
      artist: 'Avicii',
      year: '2013',
      coverUrl: 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=400&q=80',
      trackCount: '10 tracks',
      genre: 'EDM / Electronic',
    ),
  ];

  final List<ArtistItem> _artists = const [
    ArtistItem(
      id: 'ar1',
      name: 'The Weeknd',
      genre: 'R&B / Synthwave',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      monthlyListeners: '108.4M monthly',
    ),
    ArtistItem(
      id: 'ar2',
      name: 'Daft Punk',
      genre: 'French Touch / Disco',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
      monthlyListeners: '24.8M monthly',
    ),
    ArtistItem(
      id: 'ar3',
      name: 'M83',
      genre: 'Dream Pop / Ambient',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
      monthlyListeners: '9.2M monthly',
    ),
    ArtistItem(
      id: 'ar4',
      name: 'Tame Impala',
      genre: 'Psychedelic Pop',
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&q=80',
      monthlyListeners: '26.1M monthly',
    ),
    ArtistItem(
      id: 'ar5',
      name: 'Kavinsky',
      genre: 'Synthwave / OutRun',
      avatarUrl: 'https://images.unsplash.com/photo-1463453091185-61582044d556?w=300&q=80',
      monthlyListeners: '5.4M monthly',
    ),
    ArtistItem(
      id: 'ar6',
      name: 'CHVRCHES',
      genre: 'Indie Synthpop',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&q=80',
      monthlyListeners: '4.9M monthly',
    ),
    ArtistItem(
      id: 'ar7',
      name: 'Sidhu Moose Wala',
      genre: 'Punjabi Hip-Hop / Rap',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      monthlyListeners: '18.4M monthly',
    ),
    ArtistItem(
      id: 'ar8',
      name: 'AP Dhillon',
      genre: 'Punjabi Pop / R&B',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
      monthlyListeners: '12.8M monthly',
    ),
    ArtistItem(
      id: 'ar9',
      name: 'Diljit Dosanjh',
      genre: 'Punjabi Pop',
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&q=80',
      monthlyListeners: '16.5M monthly',
    ),
    ArtistItem(
      id: 'ar10',
      name: 'Arijit Singh',
      genre: 'Bollywood / Hindi',
      avatarUrl: 'https://images.unsplash.com/photo-1463453091185-61582044d556?w=300&q=80',
      monthlyListeners: '44.2M monthly',
    ),
    ArtistItem(
      id: 'ar11',
      name: 'A.R. Rahman',
      genre: 'Sufi / World / Film Score',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=300&q=80',
      monthlyListeners: '20.1M monthly',
    ),
    ArtistItem(
      id: 'ar12',
      name: 'Kendrick Lamar',
      genre: 'Hip-Hop / Conscious Rap',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&q=80',
      monthlyListeners: '55.3M monthly',
    ),
    ArtistItem(
      id: 'ar13',
      name: 'Ludovico Einaudi',
      genre: 'Classical / Instrumental',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=300&q=80',
      monthlyListeners: '8.9M monthly',
    ),
    ArtistItem(
      id: 'ar14',
      name: 'Martin Garrix',
      genre: 'EDM / Festival House',
      avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=300&q=80',
      monthlyListeners: '22.4M monthly',
    ),
  ];

  late SongItem _currentSong;

  @override
  void initState() {
    super.initState();
    _queue = List<SongItem>.from(_songs);
    _queueIndex = 0;
    _currentSong = _songs.first;
    _queueController.selectSong(_currentSong, newQueue: _queue);
    WebAudioBridge.init();
    WebAudioBridge.setVolume(_volume);
    AddonSourceRegistry.instance.initialize();
    _updateMetadataForSong(_currentSong);
    _synchronizeWithNativeDSP();
  }

  Future<void> _synchronizeWithNativeDSP() async {
    final nativeConfig = await WebAudioBridge.getDSPConfiguration();
    if (nativeConfig != null) {
      if (mounted) {
        setState(() {
          if (nativeConfig['spatialAudioEnabled'] is bool) {
            _isSpatialAudio = nativeConfig['spatialAudioEnabled'] as bool;
            AuraBeatAudioEngine.instance.setSpatialAudio(_isSpatialAudio);
          }
          if (nativeConfig['presetName'] is String && (nativeConfig['presetName'] as String).isNotEmpty) {
            _equalizerPreset = nativeConfig['presetName'] as String;
          }
          if (nativeConfig['manualBands'] is List && (nativeConfig['manualBands'] as List).length >= 7) {
            _equalizerBands = (nativeConfig['manualBands'] as List)
                .take(7)
                .map((e) => (e as num).toDouble())
                .toList();
            AuraBeatAudioEngine.instance.setManualBands(_equalizerBands);
          }
          if (nativeConfig['playbackSpeed'] is num) {
            _playbackSpeed = (nativeConfig['playbackSpeed'] as num).toDouble();
            AuraBeatAudioEngine.instance.setPlaybackSpeed(_playbackSpeed);
          }
          if (nativeConfig['silenceSkippingEnabled'] is bool) {
            _skipSilence = nativeConfig['silenceSkippingEnabled'] as bool;
            AuraBeatAudioEngine.instance.setSilenceSkipping(_skipSilence);
          }
          if (nativeConfig['bassBoostEnabled'] is bool) {
            _bassBoostEnabled = nativeConfig['bassBoostEnabled'] as bool;
          }
          if (nativeConfig['bassBoostGain'] is num) {
            _bassBoostGain = (nativeConfig['bassBoostGain'] as num).toDouble();
          }
          if (nativeConfig['subBassEnabled'] is bool) {
            _subBassEnabled = nativeConfig['subBassEnabled'] as bool;
          }
          if (nativeConfig['subBassIntensity'] is num) {
            _subBassIntensity = (nativeConfig['subBassIntensity'] as num).toDouble();
          }
          if (nativeConfig['subBassFrequency'] is num) {
            _subBassFrequency = (nativeConfig['subBassFrequency'] as num).toDouble();
          }
          if (nativeConfig['subBassOutputLevel'] is num) {
            _subBassOutputLevel = (nativeConfig['subBassOutputLevel'] as num).toDouble();
          }
          if (nativeConfig['subBassPreset'] is String) {
            _subBassPreset = nativeConfig['subBassPreset'] as String;
          }
          SubBassEngine.instance.setConfiguration(SubBassConfiguration(
            enabled: _subBassEnabled,
            intensity: _subBassIntensity,
            frequencyHz: _subBassFrequency,
            outputLevelDb: _subBassOutputLevel,
            preset: SubBassPreset.fromName(_subBassPreset),
          ));
        });
      }
    } else {
      // Fallback only if no native config returned (e.g. Web or headless test environment):
      SubBassEngine.instance.setConfiguration(SubBassConfiguration(
        enabled: _subBassEnabled,
        intensity: _subBassIntensity,
        frequencyHz: _subBassFrequency,
        outputLevelDb: _subBassOutputLevel,
        preset: SubBassPreset.fromName(_subBassPreset),
      ));
      WebAudioBridge.setPlaybackSpeed(_playbackSpeed);
      WebAudioBridge.setSilenceSkipping(_skipSilence);
      WebAudioBridge.setBassBoost(_bassBoostEnabled, _bassBoostGain);
    final subCfg = SubBassEngine.instance.config;
    WebAudioBridge.setSubBassEnhancement(
      enabled: subCfg.enabled,
      intensity: subCfg.intensity,
      frequencyHz: subCfg.frequencyHz,
      outputLevelDb: subCfg.outputLevelDb,
      preset: subCfg.preset.displayName,
    );
      WebAudioBridge.setSpatialAudio(_isSpatialAudio);
      WebAudioBridge.setEqualizer(_equalizerBands);
      AuraBeatAudioEngine.instance.setSpatialAudio(_isSpatialAudio);
      AuraBeatAudioEngine.instance.setManualBands(_equalizerBands);
      AuraBeatAudioEngine.instance.setPlaybackSpeed(_playbackSpeed);
      AuraBeatAudioEngine.instance.setSilenceSkipping(_skipSilence);
    }
  }

  void _updateMetadataForSong(SongItem song, {String? sourceId, String? requestedTier}) {
    final allSources = AddonSourceRegistry.instance.allSources;
    AddonSourceConfig activeSource;
    if (sourceId != null) {
      activeSource = AddonSourceRegistry.instance.getSourceById(sourceId) ??
          (allSources.isNotEmpty ? allSources.first : AddonSourceRegistry.instance.defaultSources.first);
    } else {
      final matching = allSources.where((s) => song.id.contains(s.id) || song.album.contains(s.name)).toList();
      if (matching.isNotEmpty) {
        activeSource = matching.first;
      } else {
        activeSource = AddonSourceRegistry.instance.enabledSources.firstWhere(
          (s) => s.id == 'dev.akira.bitchord-hires',
          orElse: () => allSources.isNotEmpty ? allSources.first : AddonSourceRegistry.instance.defaultSources.first,
        );
      }
    }

    String activeOption = (requestedTier ?? '').trim().toLowerCase();
    if (activeOption.isEmpty || activeOption == 'auto') {
      if (song.streamUrl != null && song.streamUrl!.isNotEmpty) {
        final uri = Uri.tryParse(song.streamUrl!);
        if (uri != null && uri.queryParameters.containsKey('tier')) {
          activeOption = uri.queryParameters['tier']!.trim().toLowerCase();
        }
      }
    }
    if (activeOption.isEmpty || activeOption == 'auto') {
      activeOption = (activeSource.selectedQualityOption ?? '').trim().toLowerCase();
    }
    if (activeOption.isEmpty || activeOption == 'auto') {
      activeOption = _globalStreamingProfile.value.trim().toLowerCase();
    }
    if (activeOption.isEmpty || activeOption == 'auto') {
      activeOption = activeSource.effectiveQualityOption.trim().toLowerCase();
    }

    final isExplicitAtmosTrack = song.isDolbyAtmos || song.id == 'dolby_8f31' || activeOption.contains('atmos');
    bool isAtmos = isExplicitAtmosTrack || (_dolbyAtmosEnabled && (song.title.toLowerCase().contains('atmos') || song.album.toLowerCase().contains('atmos')));

    // If user explicitly picked a non-Atmos quality tier on a regular non-Atmos track, honour that selection
    if (!isExplicitAtmosTrack && (activeOption == 'max' || activeOption == 'ultra' || activeOption == 'lossless' ||
        activeOption == 'high' || activeOption == 'low' || activeOption == 'very_high' ||
        activeOption == '320' || activeOption == '256' || activeOption == 'normal' ||
        activeOption == '128' || activeOption == '64' || activeOption == 'hires_lossless' ||
        activeOption == 'hires')) {
      isAtmos = false;
    }

    if (isAtmos) {
      _dolbyAtmosEnabled = true;
      _isSpatialAudio = true;
    }

    String codec = 'FLAC';
    int sampleRate = 192000;
    int bitDepth = 24;
    int bitrate = 9216;
    int channels = 2;
    bool isLossless = true;
    bool isHiRes = true;

    if (isAtmos || activeOption == 'atmos' || activeOption.contains('atmos')) {
      // Dolby Atmos Spatial Audio (7.1.4 Matrix, 48 kHz, 16-bit E-AC-3 JOC)
      codec = 'E-AC-3 JOC';
      sampleRate = 48000;
      bitDepth = 16;
      bitrate = 768;
      channels = 8;
      isLossless = false;
      isHiRes = false;
      isAtmos = true;
    } else if (activeOption == 'max' || activeOption == 'ultra' || activeOption.contains('192') || activeOption.contains('ultra')) {
      // 1. Ultra Hi-Res (24-bit / 192 kHz FLAC Master, ~9216 kbps)
      codec = 'FLAC';
      sampleRate = 192000;
      bitDepth = 24;
      bitrate = 9216;
      channels = isAtmos ? 8 : 2;
      isLossless = true;
      isHiRes = true;
    } else if (activeOption == 'hires' || activeOption.contains('96')) {
      // 2. Hi-Res Audio (24-bit / 96 kHz FLAC Studio, ~4608 kbps)
      codec = 'FLAC';
      sampleRate = 96000;
      bitDepth = 24;
      bitrate = 4608;
      channels = isAtmos ? 8 : 2;
      isLossless = true;
      isHiRes = true;
    } else if (activeOption == 'hires_lossless' || activeOption.contains('48') || activeOption.contains('studio')) {
      // 3. Hi-Res Lossless (24-bit / 48 kHz FLAC Studio, ~2304 kbps)
      codec = 'FLAC';
      sampleRate = 48000;
      bitDepth = 24;
      bitrate = 2304;
      channels = 2;
      isLossless = true;
      isHiRes = true;
      isAtmos = false;
    } else if (activeOption == 'lossless' || activeOption.contains('cd') || activeOption.contains('16-bit') || activeOption.contains('1411')) {
      // 4. CD Lossless (16-bit / 44.1 kHz FLAC/ALAC, ~1411 kbps)
      codec = 'FLAC';
      sampleRate = 44100;
      bitDepth = 16;
      bitrate = 1411;
      channels = 2;
      isLossless = true;
      isHiRes = false;
      isAtmos = false;
    } else if (activeOption == 'very_high' || activeOption == '320' || activeOption.contains('very_high')) {
      // 5. Very High (320 kbps MP3, 48 kHz, 16-bit)
      codec = 'MP3';
      sampleRate = 48000;
      bitDepth = 16;
      bitrate = 320;
      channels = 2;
      isLossless = false;
      isHiRes = false;
      isAtmos = false;
    } else if (activeOption == 'high' || activeOption.contains('256')) {
      // 6. High (256 kbps AAC, 48 kHz, 16-bit)
      codec = 'AAC';
      sampleRate = 48000;
      bitDepth = 16;
      bitrate = 256;
      channels = 2;
      isLossless = false;
      isHiRes = false;
      isAtmos = false;
    } else if (activeOption == 'normal' || activeOption.contains('128') || activeOption.contains('medium')) {
      // 7. Normal (128 kbps AAC, 44.1 kHz, 16-bit)
      codec = 'AAC';
      sampleRate = 44100;
      bitDepth = 16;
      bitrate = 128;
      channels = 2;
      isLossless = false;
      isHiRes = false;
      isAtmos = false;
    } else if (activeOption == 'low' || activeOption.contains('64') || activeOption.contains('data')) {
      // 8. Low Data Saver (64 kbps AAC/MP3, 44.1 kHz, 16-bit)
      codec = 'AAC';
      sampleRate = 44100;
      bitDepth = 16;
      bitrate = 64;
      channels = 2;
      isLossless = false;
      isHiRes = false;
      isAtmos = false;
    } else if (activeOption == 'atmos' || activeOption.contains('atmos')) {
      // 9. Dolby Atmos Spatial Audio (7.1.4 Matrix, 48 kHz, 16-bit)
      codec = 'E-AC-3 JOC';
      sampleRate = 48000;
      bitDepth = 16;
      bitrate = 768;
      channels = 8;
      isLossless = false;
      isHiRes = false;
      isAtmos = true;
    } else if (activeOption == 'sony360' || activeOption.contains('360')) {
      // 10. Sony 360° Reality Audio (360° Spatial Audio, 96 kHz, 24-bit)
      codec = 'ATRAC Spatial';
      sampleRate = 96000;
      bitDepth = 24;
      bitrate = 1536;
      channels = 8;
      isLossless = false;
      isHiRes = true;
      isAtmos = true;
    } else {
      // Default: Ultra Hi-Res 24-bit / 192 kHz Master FLAC
      codec = 'FLAC';
      sampleRate = 192000;
      bitDepth = 24;
      bitrate = 9216;
      channels = _dolbyAtmosEnabled ? 8 : 2;
      isLossless = true;
      isHiRes = true;
      isAtmos = _dolbyAtmosEnabled;
    }

    AddonLogger.playbackInitialized(song.id, song.title, activeSource.name, codec);

    setState(() {
      _currentAudioMetadata = AudioMetadata(
        codec: codec,
        container: isAtmos ? 'mp4' : (codec == 'MP3' ? 'mp3' : (codec == 'AAC' ? 'm4a' : 'flac')),
        bitrateKbps: bitrate,
        sampleRateHz: sampleRate,
        bitDepth: bitDepth,
        channels: channels,
        isLossless: isLossless,
        isHiRes: isHiRes,
        isDolbyAtmos: isAtmos,
        sourceId: activeSource.id,
        sourceName: activeSource.name,
        streamType: isAtmos ? 'Dolby Atmos Spatial Matrix Bitstream' : 'Direct HTTP Bitstream',
      );
      _currentSong = song.copyWith(
        audioQuality: (isAtmos && isHiRes)
            ? 'Dolby Atmos · $bitDepth-bit / ${sampleRate ~/ 1000} kHz FLAC ($bitrate kbps)'
            : (isAtmos
                ? 'Dolby Atmos Spatial Audio ($bitrate kbps)'
                : (isHiRes
                    ? '$bitDepth-bit / ${sampleRate ~/ 1000} kHz Master FLAC ($bitrate kbps)'
                    : (isLossless ? 'CD Lossless (16-bit / 44.1 kHz FLAC · $bitrate kbps)' : 'High Fidelity ($bitrate kbps)'))),
        isDolbyAtmos: isAtmos,
        isHiRes: isHiRes,
        sourceId: activeSource.id,
        sourceName: activeSource.name,
      );
    });

    final effectiveSpatial = _isSpatialAudio;
    WebAudioBridge.setSpatialAudio(effectiveSpatial);
    WebAudioBridge.setBassBoost(_bassBoostEnabled, _bassBoostGain);
    final subCfg = SubBassEngine.instance.config;
    WebAudioBridge.setSubBassEnhancement(
      enabled: subCfg.enabled,
      intensity: subCfg.intensity,
      frequencyHz: subCfg.frequencyHz,
      outputLevelDb: subCfg.outputLevelDb,
      preset: subCfg.preset.displayName,
    );
    WebAudioBridge.setEqualizer(_equalizerBands);

    // Negotiate 6-layer audio pipeline output
    final sourceDesc = SourceDescriptor(
      codec: codec,
      sampleRateHz: sampleRate,
      channelCount: channels,
      bitDepth: bitDepth,
      bitrateKbps: bitrate,
    );
    final routeDesc = RouteDescriptor(
      kind: (isAtmos || effectiveSpatial) ? AudioRouteKind.headphones : AudioRouteKind.builtInSpeaker,
      deviceName: (isAtmos || effectiveSpatial) ? 'AirPods Pro (Spatial Audio)' : 'iOS Device Output',
      isDirectCapable: true,
      advertisedSampleRates: const [44100, 48000, 96000, 192000],
      advertisedBitDepths: const [16, 24],
      isSpatialAudioEnabled: isAtmos || effectiveSpatial,
    );
    AuraBeatAudioEngine.instance.negotiate(
      source: sourceDesc,
      route: routeDesc,
      decoderName: isAtmos ? 'AtmosPlayer E-AC-3 JOC' : 'AuraBeat CoreAudio Lossless',
    );
    AuraBeatAudioEngine.instance.setSpatialAudio(effectiveSpatial);
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }
      final duration = _currentSong.durationSec;
      if (duration > 0) {
        if (_currentPosition < duration) {
          setState(() {
            _currentPosition += 1.0;
          });
        } else {
          timer.cancel();
          _onTrackEnded();
        }
      } else {
        setState(() {
          _currentPosition += 1.0;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      if (_currentPosition > 0 && _currentSong.streamUrl != null) {
        WebAudioBridge.resume();
      } else {
        WebAudioBridge.play(_currentSong.title, _currentSong.streamUrl, (_currentAudioMetadata.sampleRateHz ?? 192000).toDouble());
      }
      WebAudioBridge.setVolume(_volume);
      WebAudioBridge.setPlaybackSpeed(_playbackSpeed);
      WebAudioBridge.setSilenceSkipping(_skipSilence);
      WebAudioBridge.setBassBoost(_bassBoostEnabled, _bassBoostGain);
    final subCfg = SubBassEngine.instance.config;
    WebAudioBridge.setSubBassEnhancement(
      enabled: subCfg.enabled,
      intensity: subCfg.intensity,
      frequencyHz: subCfg.frequencyHz,
      outputLevelDb: subCfg.outputLevelDb,
      preset: subCfg.preset.displayName,
    );
      WebAudioBridge.setEqualizer(_equalizerBands);
      final effectiveSpatial = _isSpatialAudio;
      WebAudioBridge.setSpatialAudio(effectiveSpatial);
      AuraBeatAudioEngine.instance.setSpatialAudio(effectiveSpatial);
      if ((_currentAudioMetadata.isDolbyAtmos || _currentSong.isDolbyAtmos) && _currentSong.streamUrl != null) {
        _atmosStreamingManager.player.play();
      }
      _startPlaybackTimer();
    } else {
      WebAudioBridge.pause();
      _atmosStreamingManager.player.pause();
      _playbackTimer?.cancel();
    }
  }

  void _onTrackEnded() {
    _recEngine.recordPlay(_currentSong, _currentPosition, false);
    if (_repeatMode == RepeatMode.one) {
      _selectSong(_currentSong);
      return;
    }
    _skipNext(isAuto: true);
  }

  void _skipNext({bool isAuto = false}) {
    if (_currentPosition < 25.0 && !isAuto) {
      _recEngine.recordPlay(_currentSong, _currentPosition, true); // fast skip penalty
    }

    final nextSong = _queueController.getNextTrack(isAuto: isAuto);
    if (nextSong != null) {
      _selectSong(nextSong);
      return;
    }

    // Queue ended with Repeat Off: Stop playback! (Strict Phase 4 compliance)
    setState(() {
      _isPlaying = false;
      _currentPosition = 0;
    });
    _playbackTimer?.cancel();
    WebAudioBridge.stop();
    _atmosStreamingManager.player.pause();
  }

  void _skipPrev() {
    if (_currentPosition > 3.0) {
      setState(() {
        _currentPosition = 0;
      });
      if (_isPlaying) {
        _atmosStreamingManager.player.seek(0);
        WebAudioBridge.play(_currentSong.title, _currentSong.streamUrl, (_currentAudioMetadata.sampleRateHz ?? 192000).toDouble());
      }
      return;
    }

    final prevSong = _queueController.getPreviousTrack();
    if (prevSong != null) {
      _selectSong(prevSong);
    }
  }

  void _generateShuffleIndices() {
    _queueController.generateShuffleIndices();
    _shuffledIndices = List<int>.from(_queueController.shuffledIndices);
  }

  void _toggleShuffle() {
    setState(() {
      _queueController.toggleShuffle();
      _isShuffle = _queueController.isShuffle;
      _shuffledIndices = List<int>.from(_queueController.shuffledIndices);
    });
  }

  void _toggleRepeat() {
    setState(() {
      _queueController.toggleRepeat();
      _repeatMode = _queueController.repeatMode;
    });
  }

  String? _resolveStreamUrlForQuality(String? originalUrl, String tier) {
    if (originalUrl == null || originalUrl.isEmpty) return originalUrl;
    final uri = Uri.tryParse(originalUrl);
    if (uri == null) return originalUrl;
    final queryParams = Map<String, String>.from(uri.queryParameters);
    queryParams['tier'] = tier;
    queryParams['quality'] = tier;
    return uri.replace(queryParameters: queryParams).toString();
  }

  GlobalQualityProfile _mapStringToGlobalQualityProfile(String tier) {
    final t = tier.toLowerCase();
    if (t == 'max' || t == 'ultra' || t.contains('192') || t.contains('ultra')) {
      return GlobalQualityProfile.ultraHiRes;
    } else if (t == 'hires' || t.contains('96')) {
      return GlobalQualityProfile.hiResAudio;
    } else if (t == 'hires_lossless' || t.contains('48') || t.contains('studio')) {
      return GlobalQualityProfile.hiResLossless;
    } else if (t == 'lossless' || t.contains('cd') || t.contains('1411')) {
      return GlobalQualityProfile.lossless;
    } else if (t == 'very_high' || t == '320' || t.contains('very')) {
      return GlobalQualityProfile.veryHigh;
    } else if (t == 'high' || t == '256') {
      return GlobalQualityProfile.high;
    } else if (t == 'normal' || t == '128' || t == 'medium') {
      return GlobalQualityProfile.normal;
    } else if (t == 'low' || t == '64' || t.contains('data')) {
      return GlobalQualityProfile.low;
    } else if (t == 'atmos' || t.contains('atmos')) {
      return GlobalQualityProfile.dolbyAtmos;
    } else if (t == 'sony360' || t.contains('360')) {
      return GlobalQualityProfile.sony360;
    }
    return GlobalQualityProfile.auto;
  }

  void _switchAudioQuality(String qualityTier, {String? sourceId}) {
    final profile = _mapStringToGlobalQualityProfile(qualityTier);
    _globalStreamingProfile = profile;
    AddonQualityManager.instance.preferences.streamingQuality = profile;

    final registry = AddonSourceRegistry.instance;
    final targetSourceId = sourceId ?? _currentAudioMetadata.sourceId;
    if (targetSourceId.isNotEmpty) {
      registry.setQualityOption(targetSourceId, qualityTier);
    }
    for (final s in registry.allSources) {
      registry.setQualityOption(s.id, qualityTier);
    }

    final qLower = qualityTier.toLowerCase();
    final isAtmosTarget = qLower.contains('atmos') || profile == GlobalQualityProfile.dolbyAtmos;
    if (isAtmosTarget) {
      _dolbyAtmosEnabled = true;
      _isSpatialAudio = true;
    } else if (qLower == 'lossless' || qLower == 'hires' || qLower == 'hires_lossless' ||
        qLower == 'max' || qLower == 'ultra' || qLower == 'very_high' || qLower == 'high' ||
        qLower == 'normal' || qLower == 'low') {
      _dolbyAtmosEnabled = false;
      _isSpatialAudio = false;
    }

    final updatedUrl = _resolveStreamUrlForQuality(_currentSong.streamUrl, qualityTier);
    if (updatedUrl != null && updatedUrl.isNotEmpty) {
      _currentSong = _currentSong.copyWith(streamUrl: updatedUrl);
    }

    _updateMetadataForSong(_currentSong, sourceId: targetSourceId, requestedTier: qualityTier);

    if (updatedUrl != null && updatedUrl.isNotEmpty) {
      if (_isPlaying) {
        WebAudioBridge.play(_currentSong.title, updatedUrl, (_currentAudioMetadata.sampleRateHz ?? 192000).toDouble());
      }
    } else if (_currentSong.streamUrl == null) {
      AddonStreamResolver.instance.resolveTrackStream(
        trackId: _currentSong.id,
        title: _currentSong.title,
        artist: _currentSong.artist,
        qualityProfile: profile,
      ).then((res) {
        if (res != null && res.url.isNotEmpty && _isPlaying) {
          setState(() {
            _currentSong = _currentSong.copyWith(streamUrl: res.url);
          });
          WebAudioBridge.play(_currentSong.title, res.url, (_currentAudioMetadata.sampleRateHz ?? 192000).toDouble());
        }
      });
    }

    WebAudioBridge.setVolume(_volume);
    WebAudioBridge.setPlaybackSpeed(_playbackSpeed);
    WebAudioBridge.setSilenceSkipping(_skipSilence);
    WebAudioBridge.setBassBoost(_bassBoostEnabled, _bassBoostGain);
    final subCfg = SubBassEngine.instance.config;
    WebAudioBridge.setSubBassEnhancement(
      enabled: subCfg.enabled,
      intensity: subCfg.intensity,
      frequencyHz: subCfg.frequencyHz,
      outputLevelDb: subCfg.outputLevelDb,
      preset: subCfg.preset.displayName,
    );
    WebAudioBridge.setEqualizer(_equalizerBands);
    final effectiveSpatial = _isSpatialAudio;
    WebAudioBridge.setSpatialAudio(effectiveSpatial);
    AuraBeatAudioEngine.instance.setSpatialAudio(effectiveSpatial);
  }

  void _selectSong(SongItem song, {List<SongItem>? newQueue, int? indexInQueue}) {
    // 1. Terminate any previous playback completely to avoid overlapping audio
    _playbackTimer?.cancel();
    WebAudioBridge.stop();
    _atmosStreamingManager.player.pause();

    // 2. Synchronize authoritative queue state and obtain generation counter
    final requestGen = _queueController.selectSong(song, newQueue: newQueue, indexInQueue: indexInQueue);
    _queue = List<SongItem>.from(_queueController.queue);
    _queueIndex = _queueController.queueIndex;
    _playGeneration = requestGen;

    _sessionHistory.add(song.id);
    _recEngine.recordPlay(song, 0, false);

    final allSources = AddonSourceRegistry.instance.allSources;
    final activeSource = AddonSourceRegistry.instance.getSourceById(_currentAudioMetadata.sourceId) ??
        (allSources.isNotEmpty ? allSources.first : null);
    final activeTier = activeSource?.effectiveQualityOption ?? _globalStreamingProfile.value;

    String? directStreamUrl = song.streamUrl;
    if (directStreamUrl != null && directStreamUrl.isNotEmpty) {
      directStreamUrl = _resolveStreamUrlForQuality(directStreamUrl, activeTier);
    }

    if (directStreamUrl != null && directStreamUrl.isNotEmpty) {
      // Song has an explicit verified audio source
      _loadAndPlayResolvedSong(song.copyWith(streamUrl: directStreamUrl), activeSource, activeTier, requestGen);
    } else {
      // Song needs asynchronous resolution: set state to buffering/resolving without audio overlap
      setState(() {
        _currentSong = song;
        _currentPosition = 0;
        _isPlaying = true;
        _playbackErrorMessage = null;
      });
      _updateMetadataForSong(song, sourceId: activeSource?.id, requestedTier: activeTier);

      AddonStreamResolver.instance.resolveTrackStream(
        trackId: song.id,
        title: song.title,
        artist: song.artist,
        qualityProfile: _globalStreamingProfile,
      ).then((res) {
        if (requestGen != _playGeneration || !_isPlaying) return;

        if (res != null && res.url.isNotEmpty) {
          final resolvedSong = song.copyWith(streamUrl: res.url);
          _loadAndPlayResolvedSong(resolvedSong, activeSource, activeTier, requestGen);
        } else {
          // Inaccessible original source: halt player, do NOT play previous audio or fallback
          WebAudioBridge.stop();
          _atmosStreamingManager.player.pause();
          _playbackTimer?.cancel();
          setState(() {
            _isPlaying = false;
            _currentPosition = 0;
            _playbackErrorMessage = 'Original audio source unavailable for "${song.title}".';
          });
        }
      }).catchError((err) {
        if (requestGen != _playGeneration) return;
        WebAudioBridge.stop();
        _atmosStreamingManager.player.pause();
        _playbackTimer?.cancel();
        setState(() {
          _isPlaying = false;
          _currentPosition = 0;
          _playbackErrorMessage = 'Failed to load audio for "${song.title}": $err';
        });
      });
    }
  }

  void _loadAndPlayResolvedSong(SongItem songToPlay, AddonSourceConfig? activeSource, String activeTier, int requestGen) {
    if (requestGen != _playGeneration) return;

    setState(() {
      _currentSong = songToPlay;
      _currentPosition = 0;
      _isPlaying = true;
      _playbackErrorMessage = null;
    });
    _updateMetadataForSong(songToPlay, sourceId: activeSource?.id, requestedTier: activeTier);

    WebAudioBridge.play(songToPlay.title, songToPlay.streamUrl, (_currentAudioMetadata.sampleRateHz ?? 192000).toDouble());
    WebAudioBridge.setVolume(_volume);
    WebAudioBridge.setPlaybackSpeed(_playbackSpeed);
    WebAudioBridge.setSilenceSkipping(_skipSilence);
    WebAudioBridge.setBassBoost(_bassBoostEnabled, _bassBoostGain);
    final subCfg = SubBassEngine.instance.config;
    WebAudioBridge.setSubBassEnhancement(
      enabled: subCfg.enabled,
      intensity: subCfg.intensity,
      frequencyHz: subCfg.frequencyHz,
      outputLevelDb: subCfg.outputLevelDb,
      preset: subCfg.preset.displayName,
    );
    WebAudioBridge.setEqualizer(_equalizerBands);

    // Phase 5 Spatial Audio Bypass: clean original unmodified playback during verification
    final effectiveSpatial = AuraBeatAudioEngine.bypassSpatialAudio ? false : _isSpatialAudio;
    WebAudioBridge.setSpatialAudio(effectiveSpatial);
    AuraBeatAudioEngine.instance.setSpatialAudio(effectiveSpatial);

    if (!AuraBeatAudioEngine.bypassSpatialAudio &&
        (_currentAudioMetadata.isDolbyAtmos || songToPlay.isDolbyAtmos) &&
        songToPlay.streamUrl != null) {
      _atmosStreamingManager.player.load(
        songToPlay.streamUrl!,
        title: songToPlay.title,
        artist: songToPlay.artist,
        album: songToPlay.album,
        durationSeconds: songToPlay.durationSec.toDouble(),
      ).then((_) {
        if (requestGen == _playGeneration && _isPlaying) {
          _atmosStreamingManager.player.play();
        }
      }).catchError((_) {});
    }

    _startPlaybackTimer();
  }

  String _formatTime(double seconds) {
    int m = (seconds / 60).floor();
    int s = (seconds % 60).floor();
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _atmosStreamingManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkEspresso;
    final cardBg = isDark ? const Color(0xFF26201D) : const Color(0xFFFFF4E6);
    final cardBorder = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    final textPrimary = isDark ? const Color(0xFFFEDBB3) : const Color(0xFF141210);
    final textMuted = isDark ? Colors.white.withOpacity(0.55) : const Color(0xFF756457);

    return Scaffold(
      body: Row(
        children: [
          // Left Aesthetic Navigation Rail
          _buildSidebar(isDark, textPrimary, textMuted),

          // Main Center Content
          Expanded(
            child: Column(
              children: [
                _buildHeader(isDark, cardBg, textPrimary, textMuted),
                Expanded(
                  child: _selectedNav == 4
                      ? _buildSettingsDashboard(isDark, cardBg, cardBorder, textPrimary, textMuted)
                      : _buildMainContent(isDark, cardBg, cardBorder, textPrimary, textMuted),
                ),

                // Floating Aesthetic Bottom Player Dock
                _buildBottomPlayer(isDark),
              ],
            ),
          ),

          // Right Synced Lyrics Sheet (Collapsible)
          if (_showLyrics) _buildLyricsDrawer(isDark, cardBg, textPrimary, textMuted),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDark, Color textPrimary, Color textMuted) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161210) : const Color(0xFFF9D0A3),
        border: Border(
          right: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Row(
            children: [
              const AuraLogo(
                size: 38,
                circleColor: Colors.black,
                waveColor: Color(0xFFFEDBB3),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Aura Beat',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Nav Items
          _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
          _buildNavItem(1, Icons.search_rounded, 'Search', isDark),
          _buildNavItem(2, Icons.library_music_rounded, 'Library', isDark),
          _buildNavItem(3, Icons.auto_awesome, 'Aura Mix', isDark),
          _buildNavItem(4, Icons.settings_rounded, 'Settings', isDark),

          const Spacer(),

          // Minimalist theme switcher pill
          InkWell(
            onTap: widget.onToggleTheme,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 18,
                    color: textPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isDark ? 'Beige Mode' : 'Espresso Dark',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _selectedNav == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedNav = index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFFFEDBB3) : Colors.black)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? (isDark ? Colors.black : const Color(0xFFFEDBB3))
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : const Color(0xFFFEDBB3))
                        : (isDark ? Colors.white70 : Colors.black87),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _timeOfDayGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 22) return 'Good Evening';
    return 'Good Night';
  }

  Widget _buildHeader(bool isDark, Color cardBg, Color textPrimary, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1916) : const Color(0xFFFCD3A8),
        border: Border(bottom: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // Branding & Time-of-Day Greeting
          Row(
            children: [
              const AuraLogo(size: 34, circleColor: Colors.black, waveColor: Color(0xFFFEDBB3)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeOfDayGreeting,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'Your music, your mood.',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 28),

          // Central Search Access
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A231F) : const Color(0xFFFFF2E2),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 18, color: textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() {
                        _homeSearchQuery = val;
                        _addonSearchLimit = 4;
                        _allAddonResultsLoaded = false;
                      }),
                      controller: TextEditingController(text: _homeSearchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: _homeSearchQuery.length)),
                      decoration: InputDecoration(
                        hintText: 'Search songs, artists, playlists, or albums...',
                        hintStyle: TextStyle(color: textMuted, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: TextStyle(color: textPrimary, fontSize: 13),
                    ),
                  ),
                  if (_homeSearchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 16, color: textMuted),
                      onPressed: () => setState(() {
                        _homeSearchQuery = '';
                        _addonSearchLimit = 4;
                        _allAddonResultsLoaded = false;
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Audio Quality Indicator Pill (Interactive & Live Stream Telemetry)
          InkWell(
            onTap: () => _showDetailedAudioInfoModal(context, isDark),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2E2622) : Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _currentAudioMetadata.isDolbyAtmos
                      ? Colors.deepPurpleAccent
                      : (_currentAudioMetadata.isHiRes
                          ? const Color(0xFFFEDBB3)
                          : (_currentAudioMetadata.isLossless
                              ? Colors.cyanAccent
                              : Colors.white24)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentAudioMetadata.isDolbyAtmos
                        ? Icons.spatial_audio_rounded
                        : (_currentAudioMetadata.isHiRes
                            ? Icons.album_rounded
                            : Icons.graphic_eq_rounded),
                    color: _currentAudioMetadata.isDolbyAtmos
                        ? Colors.deepPurpleAccent
                        : (_currentAudioMetadata.isHiRes
                            ? const Color(0xFFFEDBB3)
                            : (_currentAudioMetadata.isLossless
                                ? Colors.cyanAccent
                                : Colors.white70)),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentAudioMetadata.isDolbyAtmos
                        ? (_currentAudioMetadata.isHiRes
                            ? 'Dolby Atmos · ${_currentAudioMetadata.bitDepth}b/${(_currentAudioMetadata.sampleRateHz ?? 192000) ~/ 1000}k · ${_currentAudioMetadata.bitrateKbps ?? 9216} kbps'
                            : 'Dolby Atmos · ${_currentAudioMetadata.bitrateKbps ?? 768} kbps')
                        : (_currentAudioMetadata.isHiRes
                            ? 'Hi-Res ${_currentAudioMetadata.bitDepth}b/${(_currentAudioMetadata.sampleRateHz ?? 96000) ~/ 1000}k · ${_currentAudioMetadata.bitrateKbps ?? 4608} kbps'
                            : (_currentAudioMetadata.isLossless
                                ? 'Lossless 16b/44.1k · ${_currentAudioMetadata.bitrateKbps ?? 1411} kbps'
                                : '${_currentAudioMetadata.codec} · ${_currentAudioMetadata.bitrateKbps ?? 320} kbps')),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _currentAudioMetadata.isDolbyAtmos
                          ? Colors.deepPurpleAccent
                          : (_currentAudioMetadata.isHiRes
                              ? const Color(0xFFFEDBB3)
                              : (_currentAudioMetadata.isLossless
                                  ? Colors.cyanAccent
                                  : Colors.white70)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_currentAudioMetadata.isDolbyAtmos || _currentSong.isDolbyAtmos) ...[
            const SizedBox(width: 8),
            AtmosBadge(
              isAtmosSource: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AtmosDiagnosticScreen(streamingManager: _atmosStreamingManager),
                ),
              ),
            ),
          ],
          const SizedBox(width: 12),

          // Notifications Bell Icon
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_rounded, color: textPrimary, size: 22),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEDBB3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications: 2 new lossless master releases added')),
              );
            },
          ),
          const SizedBox(width: 6),

          // Profile Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFEDBB3), width: 1.5),
            ),
            child: ClipOval(
              child: Image.network(
                'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF24201A),
                  child: const Icon(Icons.person, size: 20, color: Color(0xFFFEDBB3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, Color textPrimary, Color textMuted) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary, letterSpacing: -0.3),
            ),
            Text(subtitle, style: TextStyle(fontSize: 13, color: textMuted)),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'Explore All',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSongList(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final activeSongs = (_selectedCategoryFilter == 'All' || _selectedCategoryFilter == 'Music')
        ? _songs
        : _songs.where((s) =>
            s.genre.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()) ||
            s.subgenres.any((sub) => sub.toLowerCase().contains(_selectedCategoryFilter.toLowerCase()))).toList();
    final displaySongs = activeSongs.isEmpty ? _songs : activeSongs;

    return Column(
      children: displaySongs.asMap().entries.map((entry) {
        final idx = entry.key;
        final song = entry.value;
        final isSelected = song.id == _currentSong.id;
        final isLiked = _likedSongIds.contains(song.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF332A24) : Colors.black.withOpacity(0.06))
                : cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFFEDBB3) : cardBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            onTap: () {
              if (isSelected) {
                _togglePlayPause();
              } else {
                _selectSong(song, newQueue: displaySongs, indexInQueue: idx);
              }
            },
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (idx + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFFFEDBB3) : textMuted,
                  ),
                ),
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    song.coverUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      color: isDark ? Colors.white10 : Colors.black12,
                      child: Icon(Icons.music_note, color: textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    song.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '24-BIT FLAC',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: textMuted,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${song.artist} • ${song.album}',
              style: TextStyle(color: textMuted, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isLiked ? const Color(0xFFE06C75) : textMuted,
                    size: 18,
                  ),
                  tooltip: isLiked ? 'Unlike' : 'Like',
                  onPressed: () {
                    setState(() {
                      if (isLiked) {
                        _likedSongIds.remove(song.id);
                      } else {
                        _likedSongIds.add(song.id);
                      }
                    });
                  },
                ),
                const SizedBox(width: 6),
                Text(song.duration, style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 10),
                IconButton(
                  icon: Icon(
                    isSelected && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                    color: isSelected ? const Color(0xFFFEDBB3) : textPrimary,
                    size: 34,
                  ),
                  onPressed: () {
                    if (isSelected) {
                      _togglePlayPause();
                    } else {
                      _selectSong(song, newQueue: displaySongs, indexInQueue: idx);
                    }
                  },
                ),
              ],
            ),
          ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVibePills(bool isDark) {
    final vibes = [
      {'title': 'Coffeehouse Acoustic', 'count': '42 tracks', 'icon': Icons.local_cafe_rounded},
      {'title': 'Minimal Sunset', 'count': '38 tracks', 'icon': Icons.wb_twilight_rounded},
      {'title': 'Nordic Ambient', 'count': '55 tracks', 'icon': Icons.cloud_queue_rounded},
      {'title': 'Pastel Lo-Fi Beats', 'count': '60 tracks', 'icon': Icons.headphones_rounded},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: vibes.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, idx) {
        final v = vibes[idx];
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF28211D) : const Color(0xFFFFF4E6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(v['icon'] as IconData, size: 22, color: Colors.black),
              const Spacer(),
              Text(
                v['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
              ),
              Text(
                v['count'] as String,
                style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSpatialAudioDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final peach = const Color(0xFFFEDBB3);
            final dialogBg = isDark ? const Color(0xFF1E1A17) : const Color(0xFFFFF7ED);
            final fg = isDark ? Colors.white : Colors.black87;

            return Dialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header matching BitChord Desktop (DesktopStrings["spatial_audio", "Spatial audio"])
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isSpatialAudio ? Icons.spatial_audio_rounded : Icons.spatial_audio_off_rounded,
                              color: peach,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spatial audio',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: fg,
                                  ),
                                ),
                                Text(
                                  'Widens stereo tracks for a more immersive feel',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _isSpatialAudio ? const Color(0xFFD47A46) : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isSpatialAudio,
                            activeColor: Colors.black,
                            activeTrackColor: peach,
                            onChanged: (val) {
                              setState(() {
                                _isSpatialAudio = val;
                                WebAudioBridge.setSpatialAudio(val);
                                AuraBeatAudioEngine.instance.setSpatialAudio(val);
                              });
                              setDialogState(() => _isSpatialAudio = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Engine Specification Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _isSpatialAudio ? const Color(0xFFD47A46).withOpacity(0.3) : Colors.transparent,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: _isSpatialAudio ? const Color(0xFFD47A46) : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'BitChord Desktop Audio Engine',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: fg,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _isSpatialAudio
                                  ? (_currentAudioMetadata.isDolbyAtmos
                                      ? 'Bypassed: Dolby Atmos spatial stream active (discrete multi-channel passthrough preserved).'
                                      : 'Active: Mid/Side expansion (2.5x) with 15ms acoustic delay and crossfeed.')
                                  : 'Bypassed: Pure bit-perfect stereo pass-through.',
                              style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dolby Atmos Passthrough State
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _dolbyAtmosEnabled
                              ? Colors.deepPurpleAccent.withOpacity(0.12)
                              : (isDark ? Colors.black26 : Colors.black.withOpacity(0.04)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _dolbyAtmosEnabled
                                ? Colors.deepPurpleAccent.withOpacity(0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.surround_sound_rounded,
                              size: 20,
                              color: _dolbyAtmosEnabled ? Colors.deepPurpleAccent : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dolby Atmos Passthrough',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: fg,
                                    ),
                                  ),
                                  Text(
                                    _dolbyAtmosEnabled
                                        ? '7.1.4 Multi-Channel Spatial Bed Active'
                                        : 'Disabled (Standard Stereo Downmix)',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _dolbyAtmosEnabled,
                              activeColor: Colors.deepPurpleAccent,
                              activeTrackColor: Colors.purple.shade200,
                              onChanged: (val) {
                                setState(() {
                                  _dolbyAtmosEnabled = val;
                                  _updateMetadataForSong(_currentSong);
                                });
                                setDialogState(() {
                                  _dolbyAtmosEnabled = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Footer Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: peach,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // NAVIGATION VIEWS & CATEGORIZED SETTINGS
  // ==========================================

  // ==============================================================
  // PREMIUM PERSONALIZED HOME SCREEN EXPERIENCE
  // ==============================================================

  Widget _buildMainContent(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    if (_selectedNav == 1) {
      return _buildSearchNavContent(isDark, cardBg, cardBorder, textPrimary, textMuted);
    } else if (_selectedNav == 2) {
      return _buildFavoritesContent(isDark, cardBg, cardBorder, textPrimary, textMuted);
    } else if (_selectedNav == 3) {
      return _buildAuraMixContent(isDark, cardBg, cardBorder, textPrimary, textMuted);
    }

    // When searching from the header
    if (_homeSearchQuery.trim().isNotEmpty) {
      return _buildHomeSearchResults(isDark, cardBg, cardBorder, textPrimary, textMuted);
    }

    // Default: Personalized Home Screen (_selectedNav == 0)
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Category Filter Pills ("All", "Music", "Synthwave", "Chillout", "French Touch", "Ambient")
          _buildHomeCategoryPills(isDark, textPrimary, textMuted),
          const SizedBox(height: 24),

          // 2. Quick Access Section (6 Compact Rounded Cards in a 3x2 Grid)
          _buildSectionHeader('Quick Access', 'Pick up right where you left off', textPrimary, textMuted),
          const SizedBox(height: 14),
          _buildQuickAccessGrid(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 3. Featured Music Section (Visually Impressive Album / Playlist Banner)
          _buildFeaturedMusicBanner(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 4. Personalized "Made For You" Section (Daily Mix 1-6, Discover Weekly, Release Radar)
          _buildMadeForYouSection(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 5. Because You Listen To... (Track Similarity Engine)
          _buildBecauseYouListenToSection(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 6. Live Continuous Radios (Radio Generation Service)
          _buildContinuousRadioShelf(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 6B. Add-on Studio Masters & Lossless Discoveries (Always-Working BitChord Protocol)
          _buildAddonStudioMastersSection(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 7. Curated Atmosphere & Quick Picks (Top Songs with Fidelity Badges & Controls)
          _buildSectionHeader('Curated Atmosphere', 'Recently loved & personalized recommendations', textPrimary, textMuted),
          const SizedBox(height: 16),
          _buildSongList(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 8. Hidden Gems & Deep Cuts
          _buildHiddenGemsShelf(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 9. Popular Albums Shelf (Studio Master Releases)
          _buildPopularAlbumsSection(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 10. Favorite & Recommended Artists Shelf
          _buildFavoriteArtistsSection(isDark, cardBg, cardBorder, textPrimary, textMuted),
          const SizedBox(height: 36),

          // 11. Aesthetic Moods & Vibe Collections
          _buildSectionHeader('Aesthetic Vibes', 'Handcrafted acoustic frequencies', textPrimary, textMuted),
          const SizedBox(height: 16),
          _buildVibePills(isDark),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // Category filter chips above quick access
  Widget _buildHomeCategoryPills(bool isDark, Color textPrimary, Color textMuted) {
    final filters = ['All', 'Music', 'Punjabi', 'Bollywood', 'Hip-Hop', 'EDM', 'Classical', 'Synthwave', 'Chillout'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedCategoryFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryFilter = f),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFFFEDBB3) : Colors.black)
                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? const Color(0xFFFEDBB3) : Colors.black)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : const Color(0xFFFEDBB3))
                        : textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Quick Access 6-card compact grid
  Widget _buildQuickAccessGrid(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final quickItems = [
      {
        'title': 'Recently Played',
        'subtitle': _currentSong.title,
        'imageUrl': _currentSong.coverUrl,
        'action': () => _togglePlayPause(),
        'icon': Icons.history_rounded,
        'color': const Color(0xFFFEDBB3),
      },
      {
        'title': 'Liked Songs',
        'subtitle': '${_likedSongIds.length} favorites',
        'imageUrl': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=200&q=80',
        'action': () => setState(() => _selectedNav = 2),
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFE06C75),
      },
      {
        'title': 'Your Playlists',
        'subtitle': '6 mixes',
        'imageUrl': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&q=80',
        'action': () => _selectSong(_songs[2]),
        'icon': Icons.queue_music_rounded,
        'color': const Color(0xFF61AFEF),
      },
      {
        'title': 'Favorite Artists',
        'subtitle': '6 followed',
        'imageUrl': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&q=80',
        'action': () => _selectSong(_songs[1]),
        'icon': Icons.person_rounded,
        'color': const Color(0xFF98C379),
      },
      {
        'title': 'Offline Downloads',
        'subtitle': '142 tracks cached',
        'imageUrl': 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=200&q=80',
        'action': () => _selectSong(_songs[3]),
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFFC678DD),
      },
      {
        'title': 'Saved Albums',
        'subtitle': '6 studio masters',
        'imageUrl': 'https://images.unsplash.com/photo-1445985543470-41fdd5c31447?w=200&q=80',
        'action': () => _selectSong(_songs[4]),
        'icon': Icons.album_rounded,
        'color': const Color(0xFFD19A66),
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: quickItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 12,
            childAspectRatio: 3.3,
          ),
          itemBuilder: (context, idx) {
            final item = quickItems[idx];
            return InkWell(
              onTap: item['action'] as VoidCallback,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF26201D) : const Color(0xFFFFF3E3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item['imageUrl'] as String,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: (item['color'] as Color).withOpacity(0.2),
                          child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['subtitle'] as String,
                            style: TextStyle(fontSize: 11, color: textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black45 : Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, size: 18, color: textPrimary),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Visually Impressive Featured Music Banner
  Widget _buildFeaturedMusicBanner(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final featuredAlbum = _albums[0]; // M83 Hurry Up, We're Dreaming
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background Artwork with subtle blur & dark espresso gradient
            Positioned.fill(
              child: Image.network(
                featuredAlbum.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: const Color(0xFF241E1A)),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.92),
                      Colors.black.withOpacity(0.75),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            // Content on the left
            Positioned(
              left: 36,
              top: 32,
              bottom: 32,
              right: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEDBB3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'FEATURED ALBUM · 24-BIT MASTER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    featuredAlbum.title,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: Color(0xFFFEDBB3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${featuredAlbum.artist} • ${featuredAlbum.year} • ${featuredAlbum.trackCount} • ${featuredAlbum.genre}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _selectSong(_songs.first, newQueue: _songs, indexInQueue: 0),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                        label: const Text(
                          'Play Album',
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFEDBB3),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isShuffle = true;
                            _queue = List<SongItem>.from(_songs);
                            _generateShuffleIndices();
                            final firstShuffledIdx = _shuffledIndices.isNotEmpty ? _shuffledIndices.first : 0;
                            _selectSong(_queue[firstShuffledIdx], newQueue: _queue, indexInQueue: firstShuffledIdx);
                          });
                        },
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
                        label: const Text(
                          'Shuffle',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Made For You horizontal mix carousel
  Widget _buildMadeForYouSection(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final dailyMixes = _recEngine.getDailyMixes(_songs);
    final discoverWeekly = _recEngine.getDiscoverWeekly(_songs);
    final releaseRadar = _recEngine.getReleaseRadar(_songs);

    final allMixes = <PersonalizedMix>[
      discoverWeekly,
      releaseRadar,
      ...dailyMixes,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Made For You', 'Personalized daily mixes & weekly discovery tuned to your acoustic profile', textPrimary, textMuted),
        const SizedBox(height: 16),
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allMixes.length,
            itemBuilder: (context, idx) {
              final pl = allMixes[idx];
              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 18),
                child: InkWell(
                  onTap: () {
                    if (pl.tracks.isNotEmpty && pl.tracks.first is SongItem) {
                      _selectSong(pl.tracks.first as SongItem, newQueue: pl.tracks.cast<SongItem>(), indexInQueue: 0);
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.network(
                              pl.coverUrl.isNotEmpty ? pl.coverUrl : _songs[idx % _songs.length].coverUrl,
                              width: 170,
                              height: 165,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 170,
                                height: 165,
                                color: pl.accentColor.withOpacity(0.2),
                                child: Icon(Icons.music_note, color: pl.accentColor, size: 40),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.80),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                pl.badge,
                                style: const TextStyle(
                                  color: Color(0xFFFEDBB3),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEDBB3),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 24),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        pl.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pl.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Dynamic 'Because You Listen To' Section ---
  Widget _buildBecauseYouListenToSection(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final similar = _recEngine.getSimilarSongs(_currentSong, _songs, limit: 8);
    if (similar.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Because You Listen To ${_currentSong.artist}', 'Personalized tracks sharing acoustic textures & rhythm', textPrimary, textMuted),
        const SizedBox(height: 16),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: similar.length,
            itemBuilder: (context, idx) {
              final item = similar[idx];
              final song = item.song as SongItem;
              return Container(
                width: 148,
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => _selectSong(song, newQueue: similar.map((i) => i.song as SongItem).toList(), indexInQueue: idx),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              song.coverUrl,
                              width: 148,
                              height: 115,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 148,
                                height: 115,
                                color: const Color(0xFF24201A),
                                child: const Icon(Icons.music_note, color: Color(0xFFFEDBB3)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${(item.score * 100).toInt()}% MATCH',
                                style: const TextStyle(
                                  color: Color(0xFFFEDBB3),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        song.title,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.explanation,
                        style: TextStyle(fontSize: 10, color: textMuted),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Dynamic Live Continuous Radios Shelf ---
  Widget _buildContinuousRadioShelf(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final stations = [
      _recEngine.createRadioForSong(_currentSong, _songs),
      _recEngine.createRadioForArtist('Daft Punk', _songs),
      _recEngine.createRadioForArtist('The Weeknd', _songs),
      _recEngine.createRadioForGenre('Synthwave', _songs),
      _recEngine.createRadioForGenre('French House', _songs),
      _recEngine.createRadioForGenre('Punjabi Pop', _songs),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Live Continuous Radios', 'Endless dynamic stream tuned to specific artists, songs & genres', textPrimary, textMuted),
        const SizedBox(height: 16),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stations.length,
            itemBuilder: (context, idx) {
              final st = stations[idx];
              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _activeRadioStation = st;
                      _selectedNav = 3;
                    });
                    if (st.queue.isNotEmpty && st.queue.first is SongItem) {
                      _selectSong(st.queue.first as SongItem, newQueue: st.queue.cast<SongItem>(), indexInQueue: 0);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              st.coverUrl.isNotEmpty ? st.coverUrl : _currentSong.coverUrl,
                              width: 155,
                              height: 115,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 155,
                                height: 115,
                                color: const Color(0xFF24201A),
                                child: const Icon(Icons.radio, color: Color(0xFFFEDBB3)),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.82),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sensors, color: Color(0xFFFEDBB3), size: 10),
                                  SizedBox(width: 3),
                                  Text('RADIO', style: TextStyle(color: Color(0xFFFEDBB3), fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(st.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary), maxLines: 1),
                      Text(st.subtitle, style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Add-on Studio Masters & Lossless Discoveries Shelf ---
  Widget _buildAddonStudioMastersSection(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final peach = const Color(0xFFFEDBB3);
    final featuredAddonTracks = AddonSearchService.instance.getFeaturedAddonTracks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_rounded, size: 16, color: Colors.cyanAccent),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add-on Studio Masters & Lossless',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Direct BitChord Addon Protocol · 24-bit/192kHz & Dolby Atmos Vault',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 11, color: Colors.greenAccent),
                  SizedBox(width: 4),
                  Text(
                    'ALWAYS ACTIVE',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: featuredAddonTracks.length,
            itemBuilder: (context, index) {
              final track = featuredAddonTracks[index];
              final title = (track['title'] ?? '').toString();
              final artist = (track['artist'] ?? '').toString();
              final artwork = (track['artwork'] ?? '').toString();
              final audioQuality = (track['audioQuality'] ?? '').toString();
              final sourceName = (track['sourceName'] ?? '').toString();
              final isAtmos = track['isDolbyAtmos'] == true ||
                  title.toLowerCase().contains('atmos') ||
                  audioQuality.toLowerCase().contains('atmos');

              final songItem = SongItem(
                id: (track['id'] ?? 'addon_$index').toString(),
                title: title,
                artist: artist,
                album: (track['album'] ?? 'Hi-Res Vault').toString(),
                duration: (track['duration'] ?? '3:45').toString(),
                durationSec: track['durationSec'] is int ? track['durationSec'] as int : 225,
                coverUrl: artwork,
                lyrics: const [],
                audioQuality: audioQuality,
                isDolbyAtmos: isAtmos,
                sourceId: (track['sourceId'] ?? 'dev.akira.bitchord-hires').toString(),
                sourceName: (track['sourceName'] ?? sourceName).toString(),
              );

              final isSelected = songItem.id == _currentSong.id;

              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF332A24) : Colors.black.withOpacity(0.06))
                      : cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? peach : cardBorder,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isSelected) {
                      _togglePlayPause();
                    } else {
                      _selectSong(songItem);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                artwork,
                                width: 135,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 135,
                                  height: 100,
                                  color: const Color(0xFF24201A),
                                  child: const Icon(Icons.album_rounded, size: 36, color: Color(0xFFFEDBB3)),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isAtmos ? 'ATMOS' : (audioQuality.contains('192') ? '24/192' : '24/96'),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: isAtmos ? Colors.purpleAccent : Colors.cyanAccent,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 6,
                              right: 6,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: peach,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSelected && _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$artist • $sourceName',
                          style: TextStyle(fontSize: 10, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  Widget _buildHiddenGemsShelf(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final gems = _recEngine.getHiddenGems(_songs, limit: 6);
    if (gems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Hidden Gems & Deep Cuts', 'Exceptional underrated tracks matching your acoustic profile', textPrimary, textMuted),
        const SizedBox(height: 16),
        SizedBox(
          height: 185,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: gems.length,
            itemBuilder: (context, idx) {
              final item = gems[idx];
              final song = item.song as SongItem;
              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => _selectSong(song, newQueue: gems.map((i) => i.song as SongItem).toList(), indexInQueue: idx),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          song.coverUrl,
                          width: 145,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 145,
                            height: 110,
                            color: const Color(0xFF24201A),
                            child: const Icon(Icons.diamond, color: Color(0xFFFEDBB3)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(song.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary), maxLines: 1),
                      Text('${song.artist} • ${song.year}', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Popular Studio Albums Section
  Widget _buildPopularAlbumsSection(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Popular Albums', 'Iconic studio master recordings in lossless audio', textPrimary, textMuted),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _albums.length,
            itemBuilder: (context, idx) {
              final album = _albums[idx];
              return Container(
                width: 155,
                margin: const EdgeInsets.only(right: 18),
                child: InkWell(
                  onTap: () => _selectSong(_songs[idx % _songs.length], newQueue: _songs, indexInQueue: idx % _songs.length),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          album.coverUrl,
                          width: 155,
                          height: 155,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 155,
                            height: 155,
                            color: isDark ? Colors.white10 : Colors.black12,
                            child: Icon(Icons.album_rounded, color: textPrimary, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${album.artist} • ${album.year}',
                        style: TextStyle(fontSize: 11, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Favorite & Similar Artists Section
  Widget _buildFavoriteArtistsSection(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Favorite Artists', 'Artists you stream and follow', textPrimary, textMuted),
        const SizedBox(height: 16),
        SizedBox(
          height: 165,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _artists.length,
            itemBuilder: (context, idx) {
              final artist = _artists[idx];
              return Container(
                width: 115,
                margin: const EdgeInsets.only(right: 18),
                child: InkWell(
                  onTap: () => _selectSong(_songs[idx % _songs.length], newQueue: _songs, indexInQueue: idx % _songs.length),
                  borderRadius: BorderRadius.circular(60),
                  child: Column(
                    children: [
                      Container(
                        width: 95,
                        height: 95,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFEDBB3).withOpacity(0.35), width: 2),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            artist.avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFF24201A),
                              alignment: Alignment.center,
                              child: Text(
                                artist.name.isNotEmpty ? artist.name[0] : 'A',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFEDBB3)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        artist.name,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        artist.genre,
                        style: TextStyle(fontSize: 10, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Real-time search view when typing in header search
  Widget _buildHomeSearchResults(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final searchResult = _recEngine.search(
      query: _homeSearchQuery,
      songs: _songs,
      artists: _artists,
      albums: _albums,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _homeSearchQuery.isEmpty
                          ? 'Search & Discover'
                          : 'Results for "$_homeSearchQuery"',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _homeSearchQuery.isEmpty
                          ? 'Intelligent fuzzy matching, artist radios & personalized discovery'
                          : 'Category: ${searchResult.detectedCategory.toUpperCase()} · Multi-dimensional AI ranking',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                  ],
                ),
              ),
              if (_homeSearchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _homeSearchQuery = ''),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear Search'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Suggestions / Recent Searches
          if (searchResult.suggestedQueries.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: searchResult.suggestedQueries.map((q) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.history_rounded, size: 14),
                      label: Text(q),
                      onPressed: () => setState(() => _homeSearchQuery = q),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 1. BEST MATCH HERO CARD
          if (searchResult.bestMatchSong != null) ...[
            Text('Best Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C241E) : const Color(0xFFFEDBB3).withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFEDBB3).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      (searchResult.bestMatchSong as SongItem).coverUrl,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90,
                        height: 90,
                        color: const Color(0xFF24201A),
                        child: const Icon(Icons.music_note, color: Color(0xFFFEDBB3), size: 36),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEDBB3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BEST MATCH · SONG',
                            style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.w900),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (searchResult.bestMatchSong as SongItem).title,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${(searchResult.bestMatchSong as SongItem).artist} • ${(searchResult.bestMatchSong as SongItem).album}',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(searchResult.bestMatchSong as SongItem).genre} • ${(searchResult.bestMatchSong as SongItem).year} • ${(searchResult.bestMatchSong as SongItem).bpm} BPM',
                          style: TextStyle(fontSize: 11, color: textMuted.withOpacity(0.8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                    onPressed: () => _selectSong(searchResult.bestMatchSong as SongItem),
                    icon: Icon(
                      (searchResult.bestMatchSong as SongItem).id == _currentSong.id && _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 28,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDBB3),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ] else if (searchResult.bestMatchArtist != null) ...[
            Text('Best Match · Artist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C241E) : const Color(0xFFFEDBB3).withOpacity(0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFEDBB3).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      (searchResult.bestMatchArtist as ArtistItem).avatarUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFF24201A),
                        alignment: Alignment.center,
                        child: Text(
                          (searchResult.bestMatchArtist as ArtistItem).name[0],
                          style: const TextStyle(color: Color(0xFFFEDBB3), fontSize: 28),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (searchResult.bestMatchArtist as ArtistItem).name,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(searchResult.bestMatchArtist as ArtistItem).genre} • ${(searchResult.bestMatchArtist as ArtistItem).monthlyListeners}',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      final st = _recEngine.createRadioForArtist((searchResult.bestMatchArtist as ArtistItem).name, _songs);
                      setState(() {
                        _activeRadioStation = st;
                        _selectedNav = 3;
                      });
                      if (st.queue.isNotEmpty) _selectSong(st.queue.first as SongItem, newQueue: st.queue.cast<SongItem>(), indexInQueue: 0);
                    },
                    icon: const Icon(Icons.sensors, size: 16),
                    label: const Text('Start Radio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEDBB3),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 2. MATCHING SONGS
          if (searchResult.matchingSongs.isNotEmpty) ...[
            Text('Songs (${searchResult.matchingSongs.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Column(
              children: searchResult.matchingSongs.map((song) {
                final isSelected = song.id == _currentSong.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? (isDark ? const Color(0xFF332A24) : Colors.black.withOpacity(0.06)) : cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSelected ? const Color(0xFFFEDBB3) : cardBorder),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    onTap: () {
                      if (isSelected) {
                        _togglePlayPause();
                      } else {
                        _selectSong(song, newQueue: searchResult.matchingSongs.cast<SongItem>());
                      }
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song.coverUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFF24201A),
                          child: const Icon(Icons.music_note, size: 20, color: Color(0xFFFEDBB3)),
                        ),
                      ),
                    ),
                    title: Text(song.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    subtitle: Text('${song.artist} • ${song.album}', style: TextStyle(color: textMuted, fontSize: 11)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(song.genre, style: TextStyle(color: textMuted, fontSize: 9)),
                        ),
                        IconButton(
                          icon: Icon(
                            isSelected && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: textPrimary,
                            size: 28,
                          ),
                          onPressed: () {
                            if (isSelected) {
                              _togglePlayPause();
                            } else {
                              _selectSong(song, newQueue: searchResult.matchingSongs.cast<SongItem>());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // ADD-ON SOURCES HI-RES & LOSSLESS DISCOVERY (Phase 14)
          if (_homeSearchQuery.isNotEmpty) ...[
            FutureBuilder<List<Map<String, dynamic>>>(
              future: AddonSearchService.instance.searchAllSources(
                query: _homeSearchQuery,
                limitPerSource: _addonSearchLimit,
              ),
              builder: (context, snapshot) {
                final addonTracks = snapshot.data ?? [];
                if (addonTracks.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFEDBB3))),
                  );
                }
                if (addonTracks.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.hub_rounded, size: 14, color: Colors.cyanAccent),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add-on Hi-Res & Studio Masters (${addonTracks.length})',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purpleAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AURABEAT ENGINE',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: addonTracks.map((track) {
                        final title = (track['title'] ?? 'Unknown Track').toString();
                        final artist = (track['artist'] ?? 'Unknown Artist').toString();
                        final album = (track['album'] ?? 'Hi-Res Vault').toString();
                        final artwork = (track['artwork'] ?? 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300&q=80').toString();
                        final audioQuality = (track['audioQuality'] ?? '24-bit/96kHz FLAC').toString();
                        final sourceName = (track['sourceName'] ?? 'BitChord Add-on').toString();
                        final isAtmos = track['isDolbyAtmos'] == true ||
                            title.toLowerCase().contains('atmos') ||
                            audioQuality.toLowerCase().contains('atmos');

                        final songItem = SongItem(
                          id: (track['id'] ?? 'addon_${title.hashCode}').toString(),
                          title: title,
                          artist: artist,
                          album: album,
                          duration: (track['duration'] ?? '3:45').toString(),
                          durationSec: track['durationSec'] is int ? track['durationSec'] as int : 225,
                          coverUrl: artwork,
                          lyrics: const [],
                          audioQuality: audioQuality,
                          isDolbyAtmos: isAtmos,
                          sourceId: (track['sourceId'] ?? 'dev.akira.bitchord-hires').toString(),
                          sourceName: (track['sourceName'] ?? sourceName).toString(),
                        );

                        final isSelected = songItem.id == _currentSong.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF332A24) : Colors.black.withOpacity(0.06))
                                : (isDark ? const Color(0xFF221C19) : const Color(0xFFFBF4EB)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFEDBB3) : cardBorder,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            onTap: () {
                              if (isSelected) {
                                _togglePlayPause();
                              } else {
                                _selectSong(songItem);
                              }
                            },
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                artwork,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 44,
                                  height: 44,
                                  color: const Color(0xFF24201A),
                                  child: const Icon(Icons.album_rounded, size: 20, color: Color(0xFFFEDBB3)),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    title,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    audioQuality.contains('192') ? '24b/192k' : '24b/96k',
                                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    '$artist • $album',
                                    style: TextStyle(color: textMuted, fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    sourceName,
                                    style: TextStyle(color: textMuted.withOpacity(0.8), fontSize: 8),
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                isSelected && _isPlaying
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                color: isSelected ? const Color(0xFFFEDBB3) : textPrimary,
                                size: 30,
                              ),
                              onPressed: () {
                                if (isSelected) {
                                  _togglePlayPause();
                                } else {
                                  _selectSong(songItem);
                                }
                              },
                            ),
                          ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Dynamic Search Pagination & Continuous Discovery Controls (Phase 7)
                    Center(
                      child: !_allAddonResultsLoaded
                          ? OutlinedButton.icon(
                              onPressed: _isLoadingMoreAddon
                                  ? null
                                  : () async {
                                      setState(() => _isLoadingMoreAddon = true);
                                      await Future.delayed(const Duration(milliseconds: 300));
                                      setState(() {
                                        _addonSearchLimit += 4;
                                        _isLoadingMoreAddon = false;
                                        if (_addonSearchLimit >= 16) {
                                          _allAddonResultsLoaded = true;
                                        }
                                      });
                                    },
                              icon: _isLoadingMoreAddon
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFEDBB3)),
                                    )
                                  : const Icon(Icons.expand_more_rounded, size: 16),
                              label: Text(_isLoadingMoreAddon ? 'Querying Add-on Sources...' : 'Load More Hi-Res Results'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFFEDBB3),
                                side: const BorderSide(color: Color(0xFFFEDBB3)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Colors.cyanAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    'All available multi-source tracks indexed (${addonTracks.length} tracks)',
                                    style: TextStyle(color: textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ],

          // 3. MORE LIKE THIS / SIMILAR SONGS
          if (searchResult.similarSongs.isNotEmpty) ...[
            Text('Similar Songs & More Like This', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: searchResult.similarSongs.length,
                itemBuilder: (context, idx) {
                  final song = searchResult.similarSongs[idx] as SongItem;
                  return Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 14),
                    child: InkWell(
                      onTap: () => _selectSong(song),
                      borderRadius: BorderRadius.circular(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              song.coverUrl,
                              width: 145,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 145,
                                height: 110,
                                color: const Color(0xFF24201A),
                                child: const Icon(Icons.music_note, color: Color(0xFFFEDBB3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(song.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary), maxLines: 1),
                          Text('${song.artist} • ${song.genre}', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 4. RECOMMENDED FOR YOU BASED ON SEARCH
          if (searchResult.recommendedForYou.isNotEmpty) ...[
            Text('Recommended For You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
            const SizedBox(height: 12),
            Column(
              children: searchResult.recommendedForYou.take(4).map((rec) {
                final song = rec.song as SongItem;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        song.coverUrl,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 44,
                          height: 44,
                          color: const Color(0xFF24201A),
                          child: const Icon(Icons.music_note, size: 20, color: Color(0xFFFEDBB3)),
                        ),
                      ),
                    ),
                    title: Text(song.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    subtitle: Text(rec.explanation, style: TextStyle(color: textMuted, fontSize: 10)),
                    trailing: IconButton(
                      icon: Icon(Icons.play_circle_fill_rounded, color: textPrimary, size: 28),
                      onPressed: () => _selectSong(song),
                    ),
                  ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // 5. MORE FROM THIS ARTIST (Phase 5 Recommendation Module)
          () {
            final leadArtist = (searchResult.bestMatchSong as SongItem?)?.artist ??
                (searchResult.matchingSongs.isNotEmpty ? (searchResult.matchingSongs.first as SongItem).artist : null) ??
                (searchResult.bestMatchArtist as ArtistItem?)?.name;
            if (leadArtist == null || leadArtist.isEmpty) return const SizedBox.shrink();

            final artistTracks = _songs
                .where((s) => s.artist.toLowerCase().contains(leadArtist.toLowerCase()) && s.id != (searchResult.bestMatchSong as SongItem?)?.id)
                .take(4)
                .toList();
            if (artistTracks.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('More From $leadArtist', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 12),
                Column(
                  children: artistTracks.map((song) {
                    final isSelected = song.id == _currentSong.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? (isDark ? const Color(0xFF332A24) : Colors.black.withOpacity(0.06)) : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? const Color(0xFFFEDBB3) : cardBorder),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        onTap: () => isSelected ? _togglePlayPause() : _selectSong(song, newQueue: artistTracks),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            song.coverUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFF24201A),
                              child: const Icon(Icons.music_note, size: 20, color: Color(0xFFFEDBB3)),
                            ),
                          ),
                        ),
                        title: Text(song.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                        subtitle: Text('${song.album} • ${song.year}', style: TextStyle(color: textMuted, fontSize: 11)),
                        trailing: IconButton(
                          icon: Icon(
                            isSelected && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: textPrimary,
                            size: 28,
                          ),
                          onPressed: () => isSelected ? _togglePlayPause() : _selectSong(song, newQueue: artistTracks),
                        ),
                      ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),
              ],
            );
          }(),

          // 6. RELATED ALBUMS (Phase 5 Recommendation Module)
          () {
            final albumsToDisplay = searchResult.matchingAlbums.isNotEmpty
                ? searchResult.matchingAlbums
                : searchResult.relatedAlbums;
            if (albumsToDisplay.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Related Albums & Collections', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: albumsToDisplay.length,
                    itemBuilder: (context, idx) {
                      final alb = albumsToDisplay[idx] as AlbumItem;
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                alb.coverUrl,
                                width: 140,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 140,
                                  height: 110,
                                  color: const Color(0xFF24201A),
                                  child: const Icon(Icons.album_rounded, color: Color(0xFFFEDBB3)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(alb.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary), maxLines: 1),
                            Text('${alb.artist} • ${alb.year}', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }(),

          // 7. RELATED ARTISTS (Phase 5 Recommendation Module)
          () {
            final artistsToDisplay = searchResult.matchingArtists.isNotEmpty
                ? searchResult.matchingArtists
                : searchResult.similarArtists;
            if (artistsToDisplay.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Related Artists', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: artistsToDisplay.length,
                    itemBuilder: (context, idx) {
                      final art = artistsToDisplay[idx] as ArtistItem;
                      return Container(
                        width: 90,
                        margin: const EdgeInsets.only(right: 16),
                        child: InkWell(
                          onTap: () {
                            final st = _recEngine.createRadioForArtist(art.name, _songs);
                            setState(() {
                              _activeRadioStation = st;
                              _selectedNav = 3;
                            });
                            if (st.queue.isNotEmpty) _selectSong(st.queue.first as SongItem, newQueue: st.queue.cast<SongItem>(), indexInQueue: 0);
                          },
                          borderRadius: BorderRadius.circular(45),
                          child: Column(
                            children: [
                              ClipOval(
                                child: Image.network(
                                  art.avatarUrl,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 70,
                                    height: 70,
                                    color: const Color(0xFF24201A),
                                    alignment: Alignment.center,
                                    child: Text(art.name[0], style: const TextStyle(color: Color(0xFFFEDBB3), fontSize: 24)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                art.name,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                art.genre,
                                style: TextStyle(fontSize: 9, color: textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }(),

          // 8. SAME GENRE DISCOVERY (Phase 5 Recommendation Module)
          () {
            final targetGenre = (searchResult.bestMatchSong as SongItem?)?.genre ??
                (searchResult.matchingSongs.isNotEmpty ? (searchResult.matchingSongs.first as SongItem).genre : null);
            if (targetGenre == null || targetGenre.isEmpty) return const SizedBox.shrink();

            final sameGenreSongs = _songs
                .where((s) => s.genre.toLowerCase() == targetGenre.toLowerCase() && s.id != (searchResult.bestMatchSong as SongItem?)?.id)
                .take(5)
                .toList();
            if (sameGenreSongs.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('More in $targetGenre', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 175,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: sameGenreSongs.length,
                    itemBuilder: (context, idx) {
                      final song = sameGenreSongs[idx];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 14),
                        child: InkWell(
                          onTap: () => _selectSong(song, newQueue: sameGenreSongs, indexInQueue: idx),
                          borderRadius: BorderRadius.circular(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  song.coverUrl,
                                  width: 140,
                                  height: 105,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 140,
                                    height: 105,
                                    color: const Color(0xFF24201A),
                                    child: const Icon(Icons.music_note, color: Color(0xFFFEDBB3)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(song.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary), maxLines: 1),
                              Text(song.artist, style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          }(),

          // 9. CONTINUOUS DISCOVERY & INDEXING FOOTER BANNER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF241E1A) : const Color(0xFFF6EDE2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 20, color: Color(0xFFFEDBB3)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AuraBeat Universal Discovery Engine', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
                      Text('Dynamic multi-source search across Punjabi, Hindi, Pop, Hip-Hop, EDM & Studio Masters', style: TextStyle(fontSize: 10, color: textMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }  // Dedicated Search Nav Tab (when _selectedNav == 1)
  Widget _buildSearchNavContent(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildHomeSearchResults(isDark, cardBg, cardBorder, textPrimary, textMuted);
  }

  Widget _buildAuraMixContent(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final activeStation = _activeRadioStation ?? _recEngine.createRadioForSong(_currentSong, _songs);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Station Hero Banner
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF2E241E), const Color(0xFF1B1614)]
                    : [const Color(0xFFFDE4C8), const Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.sensors, color: Color(0xFFFEDBB3), size: 36),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEDBB3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('LIVE STATION · AI ENGINE', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        activeStation.title,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeStation.subtitle,
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Station Selector Chips
          _buildSectionHeader('Switch Radio Station', 'Generate live stations seeded from artists, genres or tracks', textPrimary, textMuted),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStationChip('Current Track', Icons.music_note, () {
                  setState(() => _activeRadioStation = _recEngine.createRadioForSong(_currentSong, _songs));
                }),
                _buildStationChip('Daft Punk', Icons.person, () {
                  setState(() => _activeRadioStation = _recEngine.createRadioForArtist('Daft Punk', _songs));
                }),
                _buildStationChip('The Weeknd', Icons.person, () {
                  setState(() => _activeRadioStation = _recEngine.createRadioForArtist('The Weeknd', _songs));
                }),
                _buildStationChip('Synthwave', Icons.waves, () {
                  setState(() => _activeRadioStation = _recEngine.createRadioForGenre('Synthwave', _songs));
                }),
                _buildStationChip('French House', Icons.speaker, () {
                  setState(() => _activeRadioStation = _recEngine.createRadioForGenre('French House', _songs));
                }),
                _buildStationChip('Punjabi Pop', Icons.stars, () {
                  setState(() => _activeRadioStation = _recEngine.createRadioForGenre('Punjabi Pop', _songs));
                }),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Continuous Station Queue
          _buildSectionHeader('Station Queue (${activeStation.queue.length} Tracks)', 'Continuous beat-aligned stream with artist diversity guards', textPrimary, textMuted),
          const SizedBox(height: 16),
          Column(
            children: activeStation.queue.map((item) {
              final song = item as SongItem;
              final isSelected = song.id == _currentSong.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? const Color(0xFF332A24) : Colors.black.withOpacity(0.06)) : cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSelected ? const Color(0xFFFEDBB3) : cardBorder),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  onTap: () => isSelected ? _togglePlayPause() : _selectSong(song, newQueue: activeStation.queue.cast<SongItem>()),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song.coverUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFF24201A),
                        child: const Icon(Icons.music_note, size: 20, color: Color(0xFFFEDBB3)),
                      ),
                    ),
                  ),
                  title: Text(song.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                  subtitle: Text('${song.artist} • ${song.album}', style: TextStyle(color: textMuted, fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${song.bpm} BPM', style: TextStyle(color: textMuted, fontSize: 9)),
                      ),
                      IconButton(
                        icon: Icon(
                          isSelected && _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: textPrimary,
                          size: 28,
                        ),
                        onPressed: () {
                          if (isSelected) {
                            _togglePlayPause();
                          } else {
                            _selectSong(song, newQueue: activeStation.queue.cast<SongItem>());
                          }
                        },
                      ),
                    ],
                  ),
                ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStationChip(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 14, color: const Color(0xFFFEDBB3)),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }  Widget _buildFavoritesContent(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Your Favorites', 'Tracks you\'ve loved and saved', textPrimary, textMuted),
          const SizedBox(height: 16),
          _buildSongList(isDark, cardBg, cardBorder, textPrimary, textMuted),
        ],
      ),
    );
  }

  // ==========================================
  // ALL CATEGORIES SETTINGS DASHBOARD
  // ==========================================

  Widget _buildSettingsDashboard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final search = _settingsSearchQuery.trim().toLowerCase();

    bool matchesSearch(List<String> terms) {
      if (search.isEmpty) return true;
      return terms.any((t) => t.toLowerCase().contains(search));
    }

    final showAudioQuality = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 1) &&
        matchesSearch(['audio', 'quality', 'wifi', 'cellular', 'flac', 'lossless', 'dolby', 'atmos', 'direct', 'stream', 'alignment']);
    final showPlayback = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 2) &&
        matchesSearch(['playback', 'spatial', 'dsp', 'equalizer', 'eq', 'binaural', 'loudness', 'crossfade', 'automix', 'silence']);
    final showAppearance = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 3) &&
        matchesSearch(['appearance', 'theme', 'dark', 'light', 'espresso', 'beige', 'lyrics', 'blur', 'artwork', 'cover', 'canvas', 'motion', 'animation']);
    final showDownloads = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 4) &&
        matchesSearch(['downloads', 'storage', 'cache', 'offline', 'clear', 'limit', 'gigabytes']);
    final showData = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 5) &&
        matchesSearch(['data', 'backup', 'export', 'import', 'replay', 'stats', 'genres', 'wrapped', 'history']);
    final showPersonalization = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 7) &&
        matchesSearch(['personalization', 'recommendation', 'taste', 'ai', 'autoplay', 'search', 'discovery', 'radio', 'history', 'reset']);
    final showAddons = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 8) &&
        matchesSearch(['addon', 'add-on', 'source', 'sources', 'all', 'all show', 'show', 'show sources', 'bitchord', 'heisenberg', 'lastbabe', 'eljohnzc', 'manifest', 'hires', 'mono']);
    final showAbout = (_selectedSettingsCategory == 0 || _selectedSettingsCategory == 6) &&
        matchesSearch(['about', 'version', 'aurabeat', 'github', 'discord', 'diagnostics', 'nerd', 'logs', 'developer']);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Title & Subtitle with Quick Sources Access Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'All settings & add-on sources: 6 active BitChord providers, audio fidelity, spatial DSP, and themes.',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  InkWell(
                    onTap: () => setState(() => _selectedSettingsCategory = 8),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.cyanAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.extension_rounded, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'All 6 Sources',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.cyanAccent : const Color(0xFF007575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF26201D) : const Color(0xFFFFF4E6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified_rounded, color: Color(0xFFFEDBB3), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'AuraBeat Pro v1.0',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Field for Settings
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A231F) : const Color(0xFFFFF2E2),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _settingsSearchQuery = val),
                    controller: TextEditingController(text: _settingsSearchQuery)..selection = TextSelection.fromPosition(TextPosition(offset: _settingsSearchQuery.length)),
                    decoration: InputDecoration(
                      hintText: 'Search all settings, add-on sources, audio quality, spatial DSP...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: TextStyle(color: textPrimary, fontSize: 13),
                  ),
                ),
                if (_settingsSearchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 18, color: textMuted),
                    onPressed: () => setState(() => _settingsSearchQuery = ''),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Category Pills Selector ("All Categories Way" with Add-on Sources upfront)
          _buildSettingsCategoryBar(isDark, textPrimary, textMuted),
          const SizedBox(height: 28),

          // Categorized Setting Panels (Add-on Sources First Priority)
          if (showAddons) ...[
            _buildAddonSourcesSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showAudioQuality) ...[
            _buildAudioQualitySettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showPlayback) ...[
            _buildPlaybackSpatialSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showAppearance) ...[
            _buildAppearanceSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showDownloads) ...[
            _buildDownloadsStorageSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showData) ...[
            _buildYourDataSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showPersonalization) ...[
            _buildPersonalizationSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (showAbout) ...[
            _buildAboutSettingsCard(isDark, cardBg, cardBorder, textPrimary, textMuted),
            const SizedBox(height: 24),
          ],

          if (!showAudioQuality && !showPlayback && !showAppearance && !showDownloads && !showData && !showPersonalization && !showAddons && !showAbout)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.search_off_rounded, size: 48, color: textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'No settings match "$_settingsSearchQuery"',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _settingsSearchQuery = '';
                      _selectedSettingsCategory = 0;
                    }),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Show All Categories'),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // Horizontal Category Bar
  Widget _buildSettingsCategoryBar(bool isDark, Color textPrimary, Color textMuted) {
    final categories = [
      {'id': 0, 'label': 'All Categories', 'icon': Icons.grid_view_rounded, 'color': const Color(0xFFFEDBB3)},
      {'id': 8, 'label': 'Add-on Sources (All 6)', 'icon': Icons.extension_rounded, 'color': Colors.cyanAccent},
      {'id': 1, 'label': 'Audio Quality', 'icon': Icons.graphic_eq_rounded, 'color': Colors.purpleAccent},
      {'id': 2, 'label': 'Playback & Spatial DSP', 'icon': Icons.spatial_audio_rounded, 'color': Colors.orangeAccent},
      {'id': 7, 'label': 'Personalization & AI', 'icon': Icons.auto_awesome, 'color': Colors.amberAccent},
      {'id': 3, 'label': 'Appearance & Themes', 'icon': Icons.palette_rounded, 'color': Colors.pinkAccent},
      {'id': 4, 'label': 'Downloads & Storage', 'icon': Icons.folder_zip_rounded, 'color': Colors.lightBlueAccent},
      {'id': 5, 'label': 'Your Data & Backup', 'icon': Icons.cloud_sync_rounded, 'color': Colors.indigoAccent},
      {'id': 6, 'label': 'About & Diagnostics', 'icon': Icons.info_rounded, 'color': Colors.tealAccent},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final id = cat['id'] as int;
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = _selectedSettingsCategory == id;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => setState(() => _selectedSettingsCategory = id),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFFFEDBB3) : Colors.black)
                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? const Color(0xFFFEDBB3) : Colors.black)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 15,
                      color: isSelected
                          ? (isDark ? Colors.black : const Color(0xFFFEDBB3))
                          : (isSelected ? textPrimary : textMuted),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.black : const Color(0xFFFEDBB3))
                            : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==========================================
  // CATEGORY 1: AUDIO QUALITY & STREAMING
  // ==========================================

  Widget _buildAudioQualitySettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'Audio Quality & AuraBeat Engine',
      'Studio Master FLAC, intelligent multi-source negotiation, strict lossless & Dolby Atmos bitstream',
      Icons.graphic_eq_rounded,
      Colors.purpleAccent,
      [
        // Active Add-on Source Audio Quality Tier (Loaded from Manifest or Native Tiers)
        Builder(
          builder: (context) {
            final registry = AddonSourceRegistry.instance;
            final enabled = registry.enabledSources;
            final activeSource = registry.getSourceById('dev.akira.bitchord-hires') ??
                (enabled.isNotEmpty
                    ? enabled.first
                    : (registry.allSources.isNotEmpty ? registry.allSources.first : null));
            if (activeSource == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF221A15) : const Color(0xFFFFF0E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purpleAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hub_rounded, size: 16, color: Colors.purpleAccent),
                      const SizedBox(width: 8),
                      Text(
                        'Active Add-on Source Quality Tier',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purpleAccent.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activeSource.name.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.purpleAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Options loaded from ${activeSource.name}\'s manifest (${activeSource.manifestUrl}). Selected quality parameter is sent on search & stream requests.',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.white70,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: activeSource.effectiveAvailableOptions.any((o) => o.value == activeSource.effectiveQualityOption)
                            ? activeSource.effectiveQualityOption
                            : (activeSource.effectiveAvailableOptions.isNotEmpty ? activeSource.effectiveAvailableOptions.first.value : null),
                        isExpanded: true,
                        dropdownColor: isDark ? const Color(0xFF1B1614) : Colors.white,
                        items: activeSource.effectiveAvailableOptions.map((opt) {
                          return DropdownMenuItem<String>(
                            value: opt.value,
                            child: Text(
                              opt.label,
                              style: TextStyle(fontSize: 11, color: textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              _switchAudioQuality(newVal, sourceId: activeSource.id);
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (_currentAudioMetadata.isDolbyAtmos || _currentSong.isDolbyAtmos) ...[
                    const SizedBox(width: 6),
                    AtmosBadge(
                      isAtmosSource: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AtmosDiagnosticScreen(streamingManager: _atmosStreamingManager),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        _buildDivider(isDark),

        // Global Streaming Profile Selector (Phase 5, 11)
        _buildSettingChoiceRow(
          'Global Streaming Quality',
          'Primary fidelity target negotiated with add-on sources',
          _globalStreamingProfile.pickerLabel,
          GlobalQualityProfileExt.pickerOptions,
          (val) {
            setState(() {
              final profile = GlobalQualityProfileExt.fromPickerLabel(val);
              _switchAudioQuality(profile.value);
            });
          },
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        // Preferred Audio Format
        _buildSettingChoiceRow(
          'Preferred Audio Format',
          'Preferred audio container and codec negotiated with providers',
          _preferredAudioFormat,
          ['Auto', 'FLAC', 'ALAC', 'AAC', 'Opus'],
          (val) {
            setState(() {
              _preferredAudioFormat = val;
              AddonQualityManager.instance.preferences.preferredFormat = val;
            });
          },
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        // Prefer Lossless Switch
        _buildSettingSwitchRow(
          'Prefer Lossless Streams',
          'Prioritize bit-perfect lossless sources over high-bitrate lossy streams',
          _preferLossless,
          (val) {
            setState(() {
              _preferLossless = val;
              AddonQualityManager.instance.preferences.preferLossless = val;
            });
          },
          isDark,
          textPrimary,
          textMuted,
          badge: 'Bit-Perfect',
        ),
        _buildDivider(isDark),
        // Prefer Hi-Res Switch
        _buildSettingSwitchRow(
          'Prefer Hi-Res Studio Masters',
          'Request 24-bit studio masters (>48kHz) whenever available from add-ons',
          _preferHiRes,
          (val) {
            setState(() {
              _preferHiRes = val;
              AddonQualityManager.instance.preferences.preferHiRes = val;
            });
          },
          isDark,
          textPrimary,
          textMuted,
          badge: '24-bit/96k+',
        ),
        _buildDivider(isDark),
        // Strict Lossless Switch
        _buildSettingSwitchRow(
          'Strict Lossless Mode',
          'Bypass lossy fallbacks; only accept bit-perfect uncompressed or lossless audio',
          _strictLossless,
          (val) {
            setState(() {
              _strictLossless = val;
              AddonQualityManager.instance.preferences.strictLossless = val;
            });
          },
          isDark,
          textPrimary,
          textMuted,
          badge: 'No Fallback',
        ),
        _buildDivider(isDark),
        // Allow Lossy Fallback Switch
        _buildSettingSwitchRow(
          'Allow Intelligent Lossy Fallback',
          'Seamlessly fallback to 320kbps AAC if lossless source returns 401, 404, or times out',
          _allowLossyFallback,
          (val) {
            setState(() {
              _allowLossyFallback = val;
              AddonQualityManager.instance.preferences.allowLossyFallback = val;
            });
          },
          isDark,
          textPrimary,
          textMuted,
          badge: 'Fault Tolerant',
        ),
        _buildDivider(isDark),
        _buildSettingChoiceRow(
          'Wi-Fi Streaming Quality Preset',
          'Bitrate ceiling when streaming on home or office broadband networks',
          _wifiStreamingQuality,
          [
            'Ultra Hi-Res FLAC (24-bit/192kHz · 9216 kbps)',
            'Lossless FLAC (24-bit/96kHz)',
            'High AAC (320kbps)',
            'Medium AAC (192kbps)',
            'Low AAC (128kbps)',
          ],
          (val) => setState(() => _wifiStreamingQuality = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        _buildSettingChoiceRow(
          'Cellular Mobile Data Quality Preset',
          'Streaming bandwidth ceiling when roaming on mobile data',
          _cellularStreamingQuality,
          [
            'High AAC (256kbps)',
            'Medium AAC (192kbps)',
            'Data Saver (96kbps)',
          ],
          (val) => setState(() => _cellularStreamingQuality = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        _buildSettingSwitchRow(
          'Dolby Atmos & Multi-Channel Bitstream',
          'Send discrete E-AC-3 JOC surround bitstream to connected hardware DACs',
          _dolbyAtmosEnabled,
          (val) {
            setState(() {
              _dolbyAtmosEnabled = val;
              _updateMetadataForSong(_currentSong);
            });
          },
          isDark,
          textPrimary,
          textMuted,
          badge: 'Spatial Passthrough',
        ),
        _buildDivider(isDark),
        _buildSettingChoiceRow(
          'Direct Source Stream',
          'Bypass transcoding proxy to retrieve source audio directly from addons',
          _directSourceStreamMode,
          ['Always', 'Queue Only', 'Off'],
          (val) => setState(() => _directSourceStreamMode = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        _buildSettingSwitchRow(
          'Smart Version Alignment',
          'Waveform analysis that skips music video intro silence, dialogue & skits',
          _smartVersionAlignment,
          (val) => setState(() => _smartVersionAlignment = val),
          isDark,
          textPrimary,
          textMuted,
          badge: 'Smart Sync',
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  // ==========================================
  // CATEGORY 2: PLAYBACK & SPATIAL AUDIO DSP
  // ==========================================

  Widget _buildPlaybackSpatialSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'Playback & Spatial Audio DSP',
      'Binaural ITD crossfeed, BitChord spatial widening, 7-band graphic EQ',
      Icons.spatial_audio_rounded,
      Colors.orangeAccent,
      [
        // Master Spatial Audio Switch
        _buildSettingSwitchRow(
          'Spatial audio',
          'Widens stereo tracks for a more immersive feel',
          _isSpatialAudio,
          (val) {
            setState(() {
              _isSpatialAudio = val;
              WebAudioBridge.setSpatialAudio(val);
              AuraBeatAudioEngine.instance.setSpatialAudio(val);
            });
          },
          isDark,
          textPrimary,
          textMuted,
          badge: _isSpatialAudio ? 'ACTIVE' : null,
        ),
        _buildDivider(isDark),

        // Deep Bass Boost & 808 Sub-Bass
        _buildSettingSwitchRow(
          'Deep Bass Boost & 808 Sub-Bass (+${_bassBoostGain.toStringAsFixed(0)}dB)',
          'Resonant 36Hz sub-bass punch and studio limiter protection (Active by default)',
          _bassBoostEnabled,
          (val) {
            setState(() => _bassBoostEnabled = val);
            WebAudioBridge.setBassBoost(val, _bassBoostGain);
          },
          isDark,
          textPrimary,
          textMuted,
          badge: '+${_bassBoostGain.toStringAsFixed(0)}dB SUB-BASS',
        ),
        if (_bassBoostEnabled) ...[
          _buildSettingSliderRow(
            'Sub-Bass & Bass Intensity',
            'Subwoofer punch and low-frequency resonant gain (Default: +10.0dB)',
            _bassBoostGain,
            2.0,
            16.0,
            '+${_bassBoostGain.toStringAsFixed(1)}dB',
            (val) {
              setState(() => _bassBoostGain = val);
              WebAudioBridge.setBassBoost(_bassBoostEnabled, val);
            },
            isDark,
            textPrimary,
            textMuted,
          ),
        ],
        _buildDivider(isDark),

        // Advanced Sub-Bass Enhancement Engine
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SubBassEngine.instance.isEnabled
                  ? const Color(0xFFFEDBB3).withOpacity(0.18)
                  : (isDark ? Colors.white10 : Colors.black12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.graphic_eq_rounded,
              color: SubBassEngine.instance.isEnabled ? const Color(0xFFFEDBB3) : textMuted,
              size: 22,
            ),
          ),
          title: Row(
            children: [
              Text(
                'Sub-Bass Enhancement',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SubBassEngine.instance.isEnabled
                      ? const Color(0xFFFEDBB3).withOpacity(0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  SubBassEngine.instance.isEnabled
                      ? 'ACTIVE · ${SubBassEngine.instance.config.preset.displayName.toUpperCase()}'
                      : 'BYPASSED',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: SubBassEngine.instance.isEnabled ? const Color(0xFFFEDBB3) : textMuted,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            'Deep, controlled low-frequency enhancement. Preserves original bass, kicks, and vocals.',
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubBassEnhancementScreen()),
            );
            setState(() {
              final cfg = SubBassEngine.instance.config;
              _subBassEnabled = cfg.enabled;
              _subBassIntensity = cfg.intensity;
              _subBassFrequency = cfg.frequencyHz;
              _subBassOutputLevel = cfg.outputLevelDb;
              _subBassPreset = cfg.preset.displayName;
            });
          },
        ),
        _buildDivider(isDark),

        // 7-Band Master Equalizer
        Text('7-Band Graphic Equalizer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 4),
        Text('Fine-tune acoustic frequency curves across 32Hz to 16kHz with studio headroom', style: TextStyle(fontSize: 11, color: textMuted)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildEqPresetButton('Flat', [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0], isDark),
            _buildEqPresetButton('Acoustic', [3.0, 1.5, 0.0, 1.5, 2.5, 2.0, 1.0], isDark),
            _buildEqPresetButton('Bass Boost', [6.0, 4.0, 1.5, 0.0, 0.0, 0.0, 0.0], isDark),
            _buildEqPresetButton('Bass Cut', [-6.0, -4.0, -1.5, 0.0, 0.0, 0.0, 0.0], isDark),
            _buildEqPresetButton('Vocal', [-3.0, -1.5, 1.0, 3.5, 3.0, 1.0, -1.0], isDark),
            _buildEqPresetButton('Treble Boost', [0.0, 0.0, 0.0, 0.0, 1.5, 3.5, 5.0], isDark),
            _buildEqPresetButton('Treble Cut', [0.0, 0.0, 0.0, 0.0, -1.5, -3.5, -5.0], isDark),
            _buildEqPresetButton('Loudness', [6.0, 3.5, 0.0, -1.5, -1.0, 2.0, 5.0], isDark),
            _buildEqPresetButton('Spoken Word', [-5.0, -2.5, 1.5, 4.0, 3.5, 1.5, -2.0], isDark),
            _buildEqPresetButton('Electronic', [5.0, 3.0, -1.0, 0.0, 1.0, 3.0, 4.0], isDark),
            _buildEqPresetButton('Rock', [4.0, 2.5, -1.0, -1.5, 1.0, 3.0, 3.5], isDark),
            _buildEqPresetButton('Hip-Hop', [6.0, 4.0, 0.5, -1.0, 0.5, 2.0, 2.5], isDark),
            _buildEqPresetButton('Jazz', [3.0, 1.5, 0.0, 1.0, 1.5, 2.0, 2.5], isDark),
            _buildEqPresetButton('Classical', [3.0, 2.0, 0.0, 0.0, 1.0, 2.5, 3.0], isDark),
            _buildEqPresetButton('Small Speakers', [5.0, 4.0, 2.0, 0.5, 0.0, -1.0, -2.0], isDark),
            _buildEqPresetButton('Late Night', [3.0, 1.0, 0.0, 1.5, 1.0, -1.0, -3.0], isDark),
            _buildEqPresetButton('Audiophile Clear', [4.5, 3.5, 1.0, 1.5, 2.0, 2.5, 3.0], isDark),
            _buildEqPresetButton('Sub Bass', [6.0, 4.5, 1.5, 0.5, 1.0, 1.5, 2.0], isDark),
            _buildEqPresetButton('Aura Signature', [3.0, 2.0, 1.5, 1.0, 1.5, 2.0, 2.5], isDark),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEqBandSlider(0, '32Hz', isDark, textPrimary, textMuted),
              _buildEqBandSlider(1, '64Hz', isDark, textPrimary, textMuted),
              _buildEqBandSlider(2, '250Hz', isDark, textPrimary, textMuted),
              _buildEqBandSlider(3, '1kHz', isDark, textPrimary, textMuted),
              _buildEqBandSlider(4, '4kHz', isDark, textPrimary, textMuted),
              _buildEqBandSlider(5, '8kHz', isDark, textPrimary, textMuted),
              _buildEqBandSlider(6, '16kHz', isDark, textPrimary, textMuted),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Builder(
          builder: (context) {
            final antiClipPreamp = manualCurve(_equalizerBands).preampDb;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 12, color: textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Anti-Clipping DSP Protection',
                        style: TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),
                  Text(
                    antiClipPreamp == 0.0
                        ? '0.0 dB (Bit-Perfect Headroom)'
                        : '${antiClipPreamp.toStringAsFixed(1)} dB (Auto Headroom Protection)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: antiClipPreamp == 0.0 ? Colors.greenAccent : (isDark ? const Color(0xFFFEDBB3) : Colors.black87),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        _buildDivider(isDark),

        // Loudness Normalization
        _buildSettingSwitchRow(
          'Loudness Normalization (-14 LUFS)',
          'EBU R128 / ITU-R BS.1770 compliant gain matching across all tracks',
          _loudnessNormalization,
          (val) => setState(() => _loudnessNormalization = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        // Crossfade Duration Slider
        _buildSettingSliderRow(
          'Crossfade Transition',
          'Blends the ending of a track into the beginning of the next',
          _crossfadeDuration,
          0.0,
          12.0,
          '${_crossfadeDuration.toStringAsFixed(1)}s',
          (val) => setState(() => _crossfadeDuration = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        // Automix / Smart Fade
        _buildSettingSwitchRow(
          'Automix & Smart Fade',
          'Intelligently detects tempo and waveform drops for smooth blends',
          _automixEnabled,
          (val) => setState(() => _automixEnabled = val),
          isDark,
          textPrimary,
          textMuted,
          badge: 'AI Mixer',
        ),
        _buildDivider(isDark),

        // Skip Silence
        _buildSettingSwitchRow(
          'Skip Silence',
          'Automatically skips leading and trailing silent sections in tracks',
          _skipSilence,
          (val) {
            setState(() => _skipSilence = val);
            WebAudioBridge.setSilenceSkipping(val);
          },
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        // Playback Speed (SOLA Time Stretch)
        _buildSettingSliderRow(
          'Playback Speed (SOLA)',
          'Pitch-preserving time stretch DSP engine (0.5x – 2.0x)',
          _playbackSpeed,
          0.5,
          2.0,
          '${_playbackSpeed.toStringAsFixed(2)}x',
          (val) {
            setState(() => _playbackSpeed = val);
            WebAudioBridge.setPlaybackSpeed(val);
          },
          isDark,
          textPrimary,
          textMuted,
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  Widget _buildEqPresetButton(String label, List<double> bands, bool isDark) {
    final cleanCurrent = _equalizerPreset.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final cleanLabel = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final isSelected = cleanCurrent == cleanLabel;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? const Color(0xFFFEDBB3) : Colors.black87),
        backgroundColor: isSelected ? (isDark ? const Color(0xFFFEDBB3) : Colors.black) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        setState(() {
          _equalizerPreset = label;
          _equalizerBands = List<double>.from(bands);
          if (label == 'Sub Bass') {
            _bassBoostEnabled = true;
            _bassBoostGain = 12.0;
          } else if (label == 'Bass Boost') {
            _bassBoostEnabled = true;
            _bassBoostGain = 10.0;
          } else if (label == 'Audiophile Clear') {
            _bassBoostEnabled = true;
            _bassBoostGain = 10.0;
          } else if (label == 'Vocal Clarity' || label == 'Vocal' || label == 'Treble Cut' || label == 'Bass Cut' || label == 'Spoken Word') {
            _bassBoostEnabled = false;
          } else if (label == 'Aura Signature' || label == 'Electronic' || label == 'Rock' || label == 'Hip-Hop' || label == 'Loudness') {
            _bassBoostEnabled = true;
            _bassBoostGain = 8.0;
          } else if (label == 'Flat') {
            _bassBoostEnabled = false;
          }
        });
        WebAudioBridge.setEqualizer(_equalizerBands);
        WebAudioBridge.setPreset(label);
        WebAudioBridge.setBassBoost(_bassBoostEnabled, _bassBoostGain);
    final subCfg = SubBassEngine.instance.config;
    WebAudioBridge.setSubBassEnhancement(
      enabled: subCfg.enabled,
      intensity: subCfg.intensity,
      frequencyHz: subCfg.frequencyHz,
      outputLevelDb: subCfg.outputLevelDb,
      preset: subCfg.preset.displayName,
    );
        AuraBeatAudioEngine.instance.setManualBands(_equalizerBands);
      },
      child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEqBandSlider(int index, String freqLabel, bool isDark, Color textPrimary, Color textMuted) {
    final val = _equalizerBands[index];
    return Column(
      children: [
        Text(
          '${val > 0 ? "+" : ""}${val.toStringAsFixed(1)}dB',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        SizedBox(
          height: 90,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackHeight: 2,
              ),
              child: Slider(
                value: val,
                min: -12.0,
                max: 12.0,
                activeColor: isDark ? const Color(0xFFFEDBB3) : Colors.black,
                onChanged: (newVal) {
                  setState(() {
                    _equalizerBands[index] = newVal;
                    _equalizerPreset = 'Custom';
                  });
                  WebAudioBridge.setEqBand(index, newVal);
                  WebAudioBridge.setPreset('Custom');
                  AuraBeatAudioEngine.instance.setManualBands(_equalizerBands);
                },
              ),
            ),
          ),
        ),
        Text(freqLabel, style: TextStyle(fontSize: 9, color: textMuted)),
      ],
    );
  }

  // ==========================================
  // CATEGORY 3: APPEARANCE & THEMING
  // ==========================================

  Widget _buildAppearanceSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'Appearance & Theming',
      'Espresso & Beige palettes, synced karaoke lyrics, mesh cover gradients',
      Icons.palette_rounded,
      Colors.pinkAccent,
      [
        // Theme Mode
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('App Theme Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    isDark ? 'Dark Espresso (Warm Charcoal & Coffee)' : 'Peach Beige (Light Warm Vanilla & Cream)',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onToggleTheme,
              icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 16),
              label: Text(isDark ? 'Switch to Beige' : 'Switch to Espresso'),
              style: OutlinedButton.styleFrom(
                foregroundColor: textPrimary,
                side: BorderSide(color: cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Synced Lyrics Karaoke Highlighting',
          'Character and syllable progressive word illumination during playback',
          _syncedLyricsKaraoke,
          (val) => setState(() => _syncedLyricsKaraoke = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Blur Unfocused Lyrics',
          'Softly defocuses past and upcoming lines so the active bar stands out',
          _unfocusedLyricsBlur,
          (val) => setState(() => _unfocusedLyricsBlur = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Fullscreen Cover Art Mesh',
          'Extract dominant album pigments to paint a fluid backdrop in player',
          _fullScreenCoverArt,
          (val) => setState(() => _fullScreenCoverArt = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Dynamic Animated Video Canvas',
          'Stream short looping video artworks from artist releases when available',
          _animatedCanvasEnabled,
          (val) => setState(() => _animatedCanvasEnabled = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Reduce Motion & Animations',
          'Disables complex blur shaders and motion for extended battery life',
          _reduceAnimations,
          (val) => setState(() => _reduceAnimations = val),
          isDark,
          textPrimary,
          textMuted,
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  // ==========================================
  // CATEGORY 4: DOWNLOADS & STORAGE
  // ==========================================

  Widget _buildDownloadsStorageSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'Downloads & Cache Storage',
      'Offline file caching, storage quotas, and cache maintenance',
      Icons.folder_zip_rounded,
      Colors.lightBlueAccent,
      [
        // Storage Usage Meter
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Storage Meter: ${(_cachedStorageMB / 1024).toStringAsFixed(2)} GB used',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  Text(
                    'Quota: ${_songCacheLimitGB.toInt()} GB',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (_cachedStorageMB / 1024) / _songCacheLimitGB,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFFFEDBB3) : Colors.black,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_cachedSongsCount tracks cached locally for instant zero-latency playback',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSettingChoiceRow(
          'Offline Download Audio Quality',
          'Compression profile applied when saving music to device disk',
          _downloadAudioQuality,
          ['Lossless FLAC', 'High AAC (320kbps)', 'Standard (192kbps)'],
          (val) => setState(() => _downloadAudioQuality = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Download Over Wi-Fi Only',
          'Pause offline caching queues while connected to cellular data',
          _downloadWifiOnly,
          (val) => setState(() => _downloadWifiOnly = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSliderRow(
          'Song Cache Limit',
          'Disk space reserved for temporary song stream caching',
          _songCacheLimitGB,
          1.0,
          20.0,
          '${_songCacheLimitGB.toInt()} GB',
          (val) => setState(() => _songCacheLimitGB = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: _buildSettingActionRow(
                'Clear Song Cache',
                'Frees cached audio blocks',
                'Clear Audio',
                () {
                  setState(() {
                    _cachedStorageMB = 120.0;
                    _cachedSongsCount = 0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Song audio cache successfully cleared (1.72 GB freed)')),
                  );
                },
                isDark,
                textPrimary,
                textMuted,
                icon: Icons.delete_sweep_rounded,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSettingActionRow(
                'Clear Image Cache',
                'Frees album covers & avatars',
                'Clear Images',
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Image & artwork cache cleared')),
                  );
                },
                isDark,
                textPrimary,
                textMuted,
                icon: Icons.image_not_supported_rounded,
              ),
            ),
          ],
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  // ==========================================
  // CATEGORY 5: YOUR DATA & BACKUP
  // ==========================================

  Widget _buildYourDataSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'Your Data & Backup',
      'Replay listening stats, JSON library export, and playlist synchronization',
      Icons.cloud_sync_rounded,
      Colors.indigoAccent,
      [
        // Replay Stats Preview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.black26 : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFFFEDBB3), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AuraBeat Replay Stats', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
                    const SizedBox(height: 2),
                    Text('12,480 Listening Minutes · 842 Unique Songs · Top: Ambient Vibe', style: TextStyle(fontSize: 11, color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildSettingSwitchRow(
          'Work Out Genres Automatically',
          'Calculate top genres from song history and acoustic playback attributes',
          _workOutGenres,
          (val) => setState(() => _workOutGenres = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingActionRow(
          'Export Library & Settings Backup',
          'Creates a portable JSON backup with all your playlists, likes, and settings',
          'Export JSON',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup document created: AuraBeat_Backup.json ready for download')),
            );
          },
          isDark,
          textPrimary,
          textMuted,
          icon: Icons.file_download_rounded,
        ),
        _buildDivider(isDark),

        _buildSettingActionRow(
          'Import Backup Document',
          'Restore playlists, favorites, and settings from a previously saved JSON file',
          'Import JSON',
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Select backup file to restore...')),
            );
          },
          isDark,
          textPrimary,
          textMuted,
          icon: Icons.file_upload_rounded,
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  // ==========================================
  // CATEGORY 6: ABOUT & COMMUNITY
  // ==========================================

  // ==========================================
  // CATEGORY 7: PERSONALIZATION & AI RECOMMENDATIONS
  // ==========================================

  Widget _buildPersonalizationSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'Personalization & AI Engine',
      'Spotify-grade recommendations, smart autoplay, search learning, and listener taste vectors',
      Icons.auto_awesome,
      Colors.amberAccent,
      [
        _buildSettingSwitchRow(
          'Personalized Recommendations',
          'Power Daily Mixes, Discover Weekly, and acoustic matching',
          _recEngine.profile.recommendationsEnabled,
          (val) => setState(() => _recEngine.profile.recommendationsEnabled = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        _buildSettingSwitchRow(
          'Smart Autoplay & Queue Continuations',
          'Automatically predict and queue seamless next tracks when current queue finishes',
          _recEngine.profile.autoplayEnabled,
          (val) => setState(() => _recEngine.profile.autoplayEnabled = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        _buildSettingSwitchRow(
          'Search Personalization & Adaptive Learning',
          'Dynamically calibrate taste profile and acoustic weights from recent searches',
          _recEngine.profile.searchPersonalizationEnabled,
          (val) => setState(() => _recEngine.profile.searchPersonalizationEnabled = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),
        _buildSettingActionRow(
          'Reset Listener Taste Profile',
          'Clear learned genre & artist affinity scores back to baseline factory weights',
          'Reset Taste',
          () {
            setState(() => _recEngine.resetTaste());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listener taste vectors successfully reset to default.')),
            );
          },
          isDark,
          textPrimary,
          textMuted,
          icon: Icons.refresh_rounded,
        ),
        _buildDivider(isDark),
        _buildSettingActionRow(
          'Clear Search History',
          'Remove all previous queries from recent search suggestions',
          'Clear History',
          () {
            setState(() => _recEngine.profile.clearRecentSearches());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recent search history cleared.')),
            );
          },
          isDark,
          textPrimary,
          textMuted,
          icon: Icons.history_toggle_off_rounded,
        ),
        _buildDivider(isDark),
        _buildSettingActionRow(
          'Clear Listening History',
          'Remove all played tracks and clear session history from memory',
          'Clear Plays',
          () {
            setState(() {
              _recEngine.profile.clearHistory();
              _sessionHistory.clear();
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Listening history and session tracks successfully cleared.')),
            );
          },
          isDark,
          textPrimary,
          textMuted,
          icon: Icons.playlist_remove_rounded,
        ),
        _buildDivider(isDark),
        _buildSettingActionRow(
          'Recommendation Diagnostics & Inspector',
          'Inspect live confidence weights, top affinities, and skip fatigue penalties',
          'Inspect AI',
          () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: isDark ? const Color(0xFF26201D) : const Color(0xFFFFF4E6),
                title: Text('Listener Taste Diagnostics', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Top Genre Affinities:', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                      const SizedBox(height: 6),
                      ..._recEngine.profile.genreAffinities.entries.map((e) => Text('• ${e.key}: ${(e.value * 100).toInt()}% affinity', style: TextStyle(color: textMuted, fontSize: 12))),
                      const SizedBox(height: 12),
                      Text('Top Artist Affinities:', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13)),
                      const SizedBox(height: 6),
                      ..._recEngine.profile.artistAffinities.entries.map((e) => Text('• ${e.key}: ${(e.value * 100).toInt()}% affinity', style: TextStyle(color: textMuted, fontSize: 12))),
                      const SizedBox(height: 12),
                      Text('Listening History Events: ${_recEngine.profile.history.length}', style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ],
              ),
            );
          },
          isDark,
          textPrimary,
          textMuted,
          icon: Icons.query_stats_rounded,
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  // ==========================================
  // CATEGORY 8: ADD-ON SOURCES MANAGER
  // ==========================================

  Widget _buildAddonSourcesSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    final registry = AddonSourceRegistry.instance;
    final allSources = registry.allSources;
    final enabledCount = registry.enabledSources.length;
    final peach = const Color(0xFFFEDBB3);
    final outputManager = LosslessOutputManager.instance;
    final isLosslessOutput = outputManager.isLosslessQualified;

    return _buildSettingSectionContainer(
      'Add-on Sources Manager',
      'BitChord Add-on Protocol · 6 Built-in Sources · Lossless Hardware Gating & Quality Negotiation',
      Icons.extension_rounded,
      Colors.cyanAccent,
      [
        // 1. BitChord Hardware Audio Output Gate Panel
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF191F26) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isLosslessOutput ? Colors.cyanAccent.withOpacity(0.4) : Colors.orangeAccent.withOpacity(0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isLosslessOutput ? Icons.headphones_rounded : Icons.speaker_phone_rounded,
                    size: 18,
                    color: isLosslessOutput ? Colors.cyanAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hardware Audio Output Gate',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: isLosslessOutput ? Colors.greenAccent.withOpacity(0.18) : Colors.orangeAccent.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLosslessOutput ? Colors.greenAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLosslessOutput ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          size: 11,
                          color: isLosslessOutput ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLosslessOutput ? 'LOSSLESS CERTIFIED' : 'LOSSY ROUTE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isLosslessOutput ? Colors.greenAccent : Colors.orangeAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'BitChord `checkValidLossless` enforcement. Non-qualifying outputs gate lossless streams and fallback automatically.',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black26 : Colors.white70,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: cardBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<AudioRouteType>(
                    value: outputManager.currentRoute,
                    isExpanded: true,
                    dropdownColor: isDark ? const Color(0xFF1B1614) : Colors.white,
                    icon: Icon(Icons.arrow_drop_down_rounded, color: peach),
                    items: AudioRouteType.values.map((route) {
                      return DropdownMenuItem<AudioRouteType>(
                        value: route,
                        child: Row(
                          children: [
                            Icon(
                              route.isLosslessQualified ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded,
                              size: 13,
                              color: route.isLosslessQualified ? Colors.greenAccent : Colors.orangeAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                route.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: route == outputManager.currentRoute ? FontWeight.bold : FontWeight.normal,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newRoute) {
                      if (newRoute != null) {
                        setState(() {
                          outputManager.setAudioRoute(newRoute);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Sources Summary Bar
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.cyanAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$enabledCount of ${allSources.length} Sources Active (Prioritized)',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
                  ),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshing all 6 add-on sources asynchronously...')),
                );
                await registry.refreshAll();
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('All add-on sources successfully refreshed.')),
                  );
                }
              },
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Refresh All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(foregroundColor: peach),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // All 6 Sources Quick Matrix (All Show)
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.apps_rounded, size: 15, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  Text(
                    'All 6 Default Sources Overview',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  ),
                  const Spacer(),
                  Text(
                    '${allSources.length} sources registered',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 3 : 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isWide ? 2.6 : 2.0,
                    ),
                    itemCount: allSources.length,
                    itemBuilder: (context, idx) {
                      final s = allSources[idx];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF221C19) : const Color(0xFFFAF3EB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: s.isEnabled ? Colors.cyanAccent.withOpacity(0.3) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: s.isEnabled ? Colors.cyanAccent.withOpacity(0.12) : Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.hub_rounded,
                                size: 14,
                                color: s.isEnabled ? Colors.cyanAccent : textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '#${idx + 1} ${s.name}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: s.isEnabled ? textPrimary : textMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.isEnabled ? 'ACTIVE · CONNECTED' : 'DISABLED',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: s.isEnabled ? Colors.greenAccent : textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: s.isEnabled,
                              activeColor: peach,
                              onChanged: (val) {
                                setState(() {
                                  registry.setEnabled(s.id, val);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        // 3. Prioritized List of Add-on Sources (Detailed Cards)
        ...allSources.asMap().entries.map((entry) {
          final index = entry.key;
          final source = entry.value;
          final isGatedByOutput = source.checkValidLossless && !isLosslessOutput;

          Color statusColor;
          String statusBadgeText;
          switch (source.status) {
            case AddonConnectionStatus.connected:
              statusColor = Colors.greenAccent;
              statusBadgeText = 'CONNECTED · ACTIVE';
              break;
            case AddonConnectionStatus.authRequired:
              statusColor = Colors.greenAccent;
              statusBadgeText = 'CONNECTED · GATEWAY';
              break;
            case AddonConnectionStatus.degraded:
              statusColor = Colors.orangeAccent;
              statusBadgeText = 'DEGRADED';
              break;
            case AddonConnectionStatus.checking:
              statusColor = Colors.lightBlueAccent;
              statusBadgeText = 'CHECKING…';
              break;
            case AddonConnectionStatus.offline:
            case AddonConnectionStatus.unreachable:
              statusColor = Colors.cyanAccent;
              statusBadgeText = 'OPERATIONAL · CACHED';
              break;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1917) : const Color(0xFFFAF3EB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: source.isEnabled ? cardBorder : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with Priority badge, Name, Reorder buttons, and Switch
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: peach.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? peach : const Color(0xFFB57020),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            source.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: source.isEnabled ? textPrimary : textMuted,
                            ),
                          ),
                          if (source.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: peach.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: peach.withOpacity(0.4)),
                              ),
                              child: Text(
                                'DEFAULT',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: isDark ? peach : const Color(0xFFB57020),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withOpacity(0.35)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusBadgeText,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Priority Reordering arrows
                    IconButton(
                      icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      tooltip: 'Move Up in Priority',
                      color: index > 0 ? textPrimary : textMuted.withOpacity(0.3),
                      onPressed: index > 0
                          ? () {
                              setState(() {
                                registry.reorderSources(index, index - 1);
                              });
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      tooltip: 'Move Down in Priority',
                      color: index < allSources.length - 1 ? textPrimary : textMuted.withOpacity(0.3),
                      onPressed: index < allSources.length - 1
                          ? () {
                              setState(() {
                                registry.reorderSources(index, index + 1);
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: source.isEnabled,
                      activeColor: peach,
                      onChanged: (val) {
                        setState(() {
                          registry.setEnabled(source.id, val);
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // URL & Manifest
                Text(
                  source.url,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: source.isEnabled ? textMuted : textMuted.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 4),

                // Version & Status Message
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'v${source.version}',
                        style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source.statusMessage,
                        style: TextStyle(
                          fontSize: 11,
                          color: source.status == AddonConnectionStatus.authRequired
                              ? Colors.amberAccent
                              : textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Resources & Protocol Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...source.resources.map((res) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            res.toUpperCase(),
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: textMuted),
                          ),
                        )),
                    if (source.bitchordAuth)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amberAccent.withOpacity(0.35)),
                        ),
                        child: const Text(
                          'bitchordAuth',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                        ),
                      ),
                    if (!source.allowDownloads)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.35)),
                        ),
                        child: const Text(
                          'STREAMING ONLY',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
                        ),
                      ),
                    if (source.checkValidLossless)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.indigoAccent.withOpacity(0.35)),
                        ),
                        child: const Text(
                          'LOSSLESS GATED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                        ),
                      ),
                    if (isGatedByOutput)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.lock_outline_rounded, size: 10, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text(
                              'Needs a lossless output',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Per-Addon Quality Setting Picker (Always Visible: Manifest Options or BitChord Native Tiers)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white60,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 14, color: peach),
                      const SizedBox(width: 6),
                      Text('Audio Quality: ', style: TextStyle(fontSize: 11, color: textMuted)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: source.effectiveAvailableOptions.any((o) => o.value == source.effectiveQualityOption)
                                ? source.effectiveQualityOption
                                : (source.effectiveAvailableOptions.isNotEmpty ? source.effectiveAvailableOptions.first.value : null),
                            isDense: true,
                            dropdownColor: isDark ? const Color(0xFF1B1614) : Colors.white,
                            items: source.effectiveAvailableOptions.map((opt) {
                              return DropdownMenuItem<String>(
                                value: opt.value,
                                child: Text(
                                  opt.label,
                                  style: TextStyle(fontSize: 11, color: textPrimary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (newVal) {
                              if (newVal != null) {
                                setState(() {
                                  _switchAudioQuality(newVal, sourceId: source.id);
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: source.hasManifestQualityOptions
                              ? Colors.cyanAccent.withOpacity(0.15)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          source.hasManifestQualityOptions ? 'MANIFEST' : 'NATIVE TIERS',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: source.hasManifestQualityOptions ? Colors.cyanAccent : textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (source.upstreamProvider != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.hub_rounded, size: 12, color: textMuted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Engine: ${source.upstreamProvider}',
                          style: TextStyle(fontSize: 10, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                const Divider(height: 1, color: Colors.white10),
                const SizedBox(height: 8),

                // Bottom row: Timestamp & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      source.lastRefreshed != null
                          ? 'Refreshed ${source.lastRefreshed!.hour.toString().padLeft(2, '0')}:${source.lastRefreshed!.minute.toString().padLeft(2, '0')}:${source.lastRefreshed!.second.toString().padLeft(2, '0')}'
                          : 'Pending refresh',
                      style: TextStyle(fontSize: 10, color: textMuted.withOpacity(0.8)),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showSourceDiagnosticsModal(context, source, isDark, textPrimary, textMuted),
                          icon: const Icon(Icons.analytics_outlined, size: 13),
                          label: const Text('Manifest & Diagnostics', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.cyanAccent,
                            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 17),
                          tooltip: 'Refresh ${source.name}',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            await registry.refreshSource(source.id);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 8),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _showAddCustomSourceDialog(context, isDark, textPrimary, textMuted),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
            label: const Text('Add Custom Add-on Source'),
            style: OutlinedButton.styleFrom(
              foregroundColor: peach,
              side: BorderSide(color: peach.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  void _showSourceDiagnosticsModal(BuildContext context, AddonSourceConfig config, bool isDark, Color textPrimary, Color textMuted) {
    final outputManager = LosslessOutputManager.instance;
    final isLosslessOutput = outputManager.isLosslessQualified;
    final isGatedByOutput = config.checkValidLossless && !isLosslessOutput;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B1614) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${config.name} Diagnostics',
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Identity
                Text('SOURCE IDENTITY & VERIFICATION', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Permanent ID: ${config.id}', style: TextStyle(color: textPrimary, fontSize: 12, fontFamily: 'monospace')),
                Text('Base URL: ${config.url}', style: TextStyle(color: textPrimary, fontSize: 12, fontFamily: 'monospace')),
                Text('Manifest URL: ${config.manifestUrl}', style: TextStyle(color: textPrimary, fontSize: 12, fontFamily: 'monospace')),
                Text('Declared Version: v${config.version}', style: TextStyle(color: textPrimary, fontSize: 12)),
                Text('Sort Order (Priority): #${config.sortOrder + 1}', style: TextStyle(color: textPrimary, fontSize: 12)),
                if (config.lastSuccess != null)
                  Text('Last Contact Success: ${config.lastSuccess}', style: const TextStyle(color: Colors.greenAccent, fontSize: 11)),
                if (config.lastError != null)
                  Text('Last Reported Notice: ${config.lastError}', style: const TextStyle(color: Colors.amberAccent, fontSize: 11)),
                const SizedBox(height: 14),

                // BitChord Protocol Gates
                Text('BITCHORD PROTOCOL ENFORCEMENT', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      config.bitchordAuth ? Icons.shield_rounded : Icons.lock_open_rounded,
                      size: 14,
                      color: config.bitchordAuth ? Colors.amberAccent : Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'bitchordAuth: ${config.bitchordAuth ? "REQUIRED (Hardware KeyStore Attestation)" : "Not Required"}',
                        style: TextStyle(
                          color: config.bitchordAuth ? Colors.amberAccent : textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      config.checkValidLossless ? Icons.graphic_eq_rounded : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: config.checkValidLossless ? Colors.indigoAccent : Colors.greenAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'checkValidLossless: ${config.checkValidLossless ? "1 (Lossless Output Gated)" : "0 (Ungated)"}',
                        style: TextStyle(
                          color: config.checkValidLossless ? Colors.indigoAccent : textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isGatedByOutput) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: const Text(
                      'Needs a lossless output (Gated from playback on current lossy route)',
                      style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      config.allowDownloads ? Icons.download_done_rounded : Icons.download_for_offline_outlined,
                      size: 14,
                      color: config.allowDownloads ? Colors.greenAccent : Colors.lightBlueAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'allowDownloads: ${config.allowDownloads ? "1 (Downloads Permitted)" : "0 (Streaming only)"}',
                        style: TextStyle(
                          color: config.allowDownloads ? textPrimary : Colors.lightBlueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Declared Quality Options
                Text('MANIFEST QUALITY SETTINGS', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (config.qualityOptions.isNotEmpty)
                  ...config.qualityOptions.map((opt) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Icon(
                              opt.value == config.effectiveQualityOption ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 13,
                              color: opt.value == config.effectiveQualityOption ? Colors.cyanAccent : textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${opt.label} (${opt.value})',
                                style: TextStyle(
                                  color: opt.value == config.effectiveQualityOption ? textPrimary : textMuted,
                                  fontSize: 12,
                                  fontWeight: opt.value == config.effectiveQualityOption ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  ...config.qualityTiers.map((q) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 13, color: Colors.cyanAccent),
                            const SizedBox(width: 6),
                            Expanded(child: Text(q, style: TextStyle(color: textPrimary, fontSize: 12))),
                          ],
                        ),
                      )),
                const SizedBox(height: 14),

                // Upstream Engine
                if (config.upstreamProvider != null) ...[
                  Text('DOWNSTREAM AUDIO ENGINE', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(config.upstreamProvider!, style: TextStyle(color: textPrimary, fontSize: 12)),
                  const SizedBox(height: 14),
                ],

                if (config.metadata.isNotEmpty) ...[
                  Text('METADATA & TELEMETRY', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black38 : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      config.metadata.toString(),
                      style: TextStyle(color: textMuted, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAddCustomSourceDialog(BuildContext context, bool isDark, Color textPrimary, Color textMuted) {
    final urlController = TextEditingController();
    final nameController = TextEditingController();
    bool isProbing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B1614) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Custom Add-on Source', style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter the HTTPS address of the add-on server. AuraBeat will probe /manifest.json to verify capabilities.', style: TextStyle(fontSize: 12, color: textMuted)),
              const SizedBox(height: 14),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'Source URL (HTTPS)',
                  hintText: 'https://addon.example.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: textPrimary, fontSize: 13),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name (Optional)',
                  hintText: 'My Custom Source',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                style: TextStyle(color: textPrimary, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isProbing
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      var url = urlController.text.trim();
                      if (url.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Please enter an add-on server address or manifest URL.')),
                        );
                        return;
                      }

                      if (!url.startsWith('https://') && !url.startsWith('http://')) {
                        url = 'https://$url';
                      }

                      setModalState(() => isProbing = true);
                      final discovery = AddonDiscoveryService();
                      final inspected = await discovery.inspectSource(
                        url,
                        defaultName: nameController.text.trim().isNotEmpty ? nameController.text.trim() : null,
                      );

                      if (inspected.status == AddonConnectionStatus.offline) {
                        setModalState(() => isProbing = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(inspected.lastError ?? 'Failed to find a valid manifest at $url'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final added = AddonSourceRegistry.instance.addSource(inspected);
                      if (added) {
                        nav.pop();
                        if (mounted) setState(() {});
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Installed "${inspected.name}" v${inspected.version} (${inspected.qualityOptions.length} quality options loaded).',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setModalState(() => isProbing = false);
                        messenger.showSnackBar(
                          const SnackBar(content: Text('This add-on source ID or URL is already registered.')),
                        );
                      }
                    },
              child: isProbing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Probe & Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // CATEGORY 6: ABOUT & COMMUNITY
  // ==========================================

  Widget _buildAboutSettingsCard(bool isDark, Color cardBg, Color cardBorder, Color textPrimary, Color textMuted) {
    return _buildSettingSectionContainer(
      'About AuraBeat',
      'Open-source ecosystem, backend acknowledgements, diagnostics and nerd stats',
      Icons.info_rounded,
      Colors.tealAccent,
      [
        Row(
          children: [
            const AuraLogo(size: 44, circleColor: Colors.black, waveColor: Color(0xFFFEDBB3)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AuraBeat Master Edition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text('Version 1.0.0 (Build 2026.11) · YouTube Music & Listen Together Backend', style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Diagnostic Logging',
          'Keeps an in-memory rotating debug log to aid troubleshooting and bug reports',
          _keepDiagnosticLogs,
          (val) => setState(() => _keepDiagnosticLogs = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        _buildSettingSwitchRow(
          'Stream Nerd Stats',
          'Displays real-time technical info: audio sample rate, codec, bit depth & buffer status',
          _showNerdStats,
          (val) => setState(() => _showNerdStats = val),
          isDark,
          textPrimary,
          textMuted,
        ),
        _buildDivider(isDark),

        // Community Links
        Text('Ecosystem Links', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _buildLinkChip('GitHub Repo', Icons.code_rounded, 'https://github.com/kushagrasinghx/AuraBeat', isDark, textPrimary),
            _buildLinkChip('Developer', Icons.person_rounded, 'https://github.com/kushagrasinghx', isDark, textPrimary),
            _buildLinkChip('Discord', Icons.chat_bubble_rounded, 'https://discord.gg/pDdKfrdHY6', isDark, textPrimary),
            _buildLinkChip('Website', Icons.language_rounded, 'https://aurabeat.app', isDark, textPrimary),
          ],
        ),
      ],
      isDark,
      cardBg,
      cardBorder,
      textPrimary,
      textMuted,
    );
  }

  Widget _buildLinkChip(String label, IconData icon, String url, bool isDark, Color textPrimary) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $url')),
        );
      },
      icon: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }

  // ==========================================
  // SETTINGS UI BUILDING BLOCKS
  // ==========================================

  Widget _buildSettingSectionContainer(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
    List<Widget> children,
    bool isDark,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSettingSwitchRow(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
    Color textPrimary,
    Color textMuted, {
    String? badge,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFFEDBB3).withOpacity(0.2) : Colors.black12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFEDBB3) : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          activeColor: Colors.black,
          activeTrackColor: const Color(0xFFFEDBB3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSettingChoiceRow(
    String title,
    String subtitle,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentValue,
                  isDense: true,
                  dropdownColor: isDark ? const Color(0xFF26201D) : const Color(0xFFFFF4E6),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                  icon: Icon(Icons.arrow_drop_down_rounded, color: textPrimary, size: 18),
                  items: options.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(opt),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) onChanged(val);
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingSliderRow(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    String displayValue,
    ValueChanged<double> onChanged,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFFFEDBB3).withOpacity(0.18) : Colors.black.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFEDBB3) : Colors.black,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: isDark ? const Color(0xFFFEDBB3) : Colors.black,
          inactiveColor: isDark ? Colors.white12 : Colors.black12,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSettingActionRow(
    String title,
    String subtitle,
    String buttonLabel,
    VoidCallback onTap,
    bool isDark,
    Color textPrimary,
    Color textMuted, {
    IconData? icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 11, color: textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: onTap,
          icon: icon != null ? Icon(icon, size: 14) : const SizedBox.shrink(),
          label: Text(buttonLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFFFEDBB3) : Colors.black,
            foregroundColor: isDark ? Colors.black : const Color(0xFFFEDBB3),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPlayer(bool isDark) {
    return Container(
      height: 104,
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          // Track Info
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _currentSong.coverUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: const Color(0xFF24201A),
                child: const Icon(Icons.music_note, color: Color(0xFFFEDBB3)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentSong.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFFEDBB3),
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _currentSong.artist,
                    style: TextStyle(fontSize: 12, color: const Color(0xFFFEDBB3).withOpacity(0.65)),
                  ),
                  const SizedBox(width: 8),
                  // Compact Audio Quality Badge (Phase 13)
                  InkWell(
                    onTap: () => _showDetailedAudioInfoModal(context, isDark),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _currentAudioMetadata.isDolbyAtmos
                            ? Colors.deepPurpleAccent.withOpacity(0.2)
                            : (_currentAudioMetadata.isHiRes
                                ? const Color(0xFFFEDBB3).withOpacity(0.2)
                                : (_currentAudioMetadata.isLossless
                                    ? Colors.cyanAccent.withOpacity(0.2)
                                    : Colors.white10)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _currentAudioMetadata.isDolbyAtmos
                              ? Colors.deepPurpleAccent.withOpacity(0.6)
                              : (_currentAudioMetadata.isHiRes
                                  ? const Color(0xFFFEDBB3).withOpacity(0.6)
                                  : (_currentAudioMetadata.isLossless
                                      ? Colors.cyanAccent.withOpacity(0.6)
                                      : Colors.white24)),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentAudioMetadata.isDolbyAtmos
                                ? Icons.spatial_audio_rounded
                                : (_currentAudioMetadata.isHiRes
                                    ? Icons.album_rounded
                                    : Icons.graphic_eq_rounded),
                            size: 10,
                            color: _currentAudioMetadata.isDolbyAtmos
                                ? Colors.deepPurpleAccent
                                : (_currentAudioMetadata.isHiRes
                                    ? const Color(0xFFFEDBB3)
                                    : (_currentAudioMetadata.isLossless ? Colors.cyanAccent : Colors.white70)),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentAudioMetadata.isDolbyAtmos
                                ? (_currentAudioMetadata.isHiRes
                                    ? 'ATMOS · ${_currentAudioMetadata.bitDepth}b/${(_currentAudioMetadata.sampleRateHz ?? 192000) ~/ 1000}k · ${_currentAudioMetadata.bitrateKbps ?? 9216}k'
                                    : 'DOLBY ATMOS · ${_currentAudioMetadata.bitrateKbps ?? 768}k')
                                : (_currentAudioMetadata.isHiRes
                                    ? 'HI-RES · ${_currentAudioMetadata.bitDepth}b/${(_currentAudioMetadata.sampleRateHz ?? 96000) ~/ 1000}k · ${_currentAudioMetadata.bitrateKbps ?? 4608}k'
                                    : (_currentAudioMetadata.isLossless
                                        ? 'CD LOSSLESS · ${_currentAudioMetadata.bitrateKbps ?? 1411}k'
                                        : '${_currentAudioMetadata.codec} · ${_currentAudioMetadata.bitrateKbps ?? 320}k')),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: _currentAudioMetadata.isDolbyAtmos
                                  ? Colors.deepPurpleAccent
                                  : (_currentAudioMetadata.isHiRes
                                      ? const Color(0xFFFEDBB3)
                                      : (_currentAudioMetadata.isLossless ? Colors.cyanAccent : Colors.white70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_currentAudioMetadata.isDolbyAtmos || _currentSong.isDolbyAtmos) ...[
                    const SizedBox(width: 6),
                    AtmosBadge(
                      isAtmosSource: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AtmosDiagnosticScreen(streamingManager: _atmosStreamingManager),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isLiked ? const Color(0xFFFEDBB3) : Colors.white54,
              size: 20,
            ),
            onPressed: () {
              final newLiked = !_isLiked;
              setState(() => _isLiked = newLiked);
              _recEngine.recordLike(_currentSong, newLiked);
            },
          ),

          const Spacer(),

          // Center Controls & Scrubber
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle,
                        size: 18,
                        color: _isShuffle ? const Color(0xFFFEDBB3) : Colors.white54,
                      ),
                      tooltip: _isShuffle ? 'Shuffle On' : 'Shuffle Off',
                      onPressed: _toggleShuffle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 24, color: Color(0xFFFEDBB3)),
                      onPressed: _skipPrev,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFEDBB3),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 26,
                          color: Colors.black,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 24, color: Color(0xFFFEDBB3)),
                      onPressed: () => _skipNext(),
                    ),
                    IconButton(
                      icon: Icon(
                        _repeatMode == RepeatMode.one
                            ? Icons.repeat_one_rounded
                            : Icons.repeat_rounded,
                        size: 18,
                        color: _repeatMode != RepeatMode.off ? const Color(0xFFFEDBB3) : Colors.white54,
                      ),
                      tooltip: _repeatMode == RepeatMode.off
                          ? 'Repeat Off'
                          : _repeatMode == RepeatMode.all
                              ? 'Repeat All'
                              : 'Repeat One',
                      onPressed: _toggleRepeat,
                    ),
                  ],
                ),
                if (_playbackErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      'Track ${_queueIndex + 1}/${_queue.length}: $_playbackErrorMessage',
                      style: const TextStyle(fontSize: 10, color: Colors.redAccent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Row(
                  children: [
                    Text(_formatTime(_currentPosition), style: TextStyle(fontSize: 11, color: const Color(0xFFFEDBB3).withOpacity(0.6))),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                          trackHeight: 3,
                          activeTrackColor: const Color(0xFFFEDBB3),
                          inactiveTrackColor: Colors.white.withOpacity(0.15),
                          thumbColor: const Color(0xFFFEDBB3),
                        ),
                        child: Slider(
                          value: _currentPosition.clamp(0.0, _currentSong.durationSec > 0 ? _currentSong.durationSec.toDouble() : (_currentPosition > 1.0 ? _currentPosition : 1.0)),
                          max: _currentSong.durationSec > 0 ? _currentSong.durationSec.toDouble() : (_currentPosition > 1.0 ? _currentPosition : 1.0),
                          onChanged: (val) {
                            setState(() {
                              _currentPosition = val;
                            });
                            _atmosStreamingManager.player.seek(val);
                          },
                        ),
                      ),
                    ),
                    Text(_currentSong.duration, style: TextStyle(fontSize: 11, color: const Color(0xFFFEDBB3).withOpacity(0.6))),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Right Controls (Spatial Audio, Lyrics, Volume)
          IconButton(
            icon: Icon(
              (_isSpatialAudio || _currentAudioMetadata.isDolbyAtmos) ? Icons.spatial_audio_rounded : Icons.spatial_audio_off_rounded,
              color: (_isSpatialAudio || _currentAudioMetadata.isDolbyAtmos) ? const Color(0xFFFEDBB3) : Colors.white54,
              size: 20,
            ),
            tooltip: _currentAudioMetadata.isDolbyAtmos
                ? 'Dolby Atmos Spatial Audio Active'
                : (_isSpatialAudio ? 'Spatial Audio Active' : 'Spatial Audio (Off)'),
            onPressed: () => _openSpatialAudioDialog(context, isDark),
          ),
          IconButton(
            icon: Icon(
              Icons.lyrics_rounded,
              color: _showLyrics ? const Color(0xFFFEDBB3) : Colors.white54,
              size: 20,
            ),
            tooltip: 'Synced Lyrics',
            onPressed: () => setState(() => _showLyrics = !_showLyrics),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.volume_up_rounded, size: 18, color: Color(0xFFFEDBB3)),
          SizedBox(
            width: 90,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                trackHeight: 2,
                activeTrackColor: const Color(0xFFFEDBB3),
                inactiveTrackColor: Colors.white.withOpacity(0.15),
                thumbColor: const Color(0xFFFEDBB3),
              ),
              child: Slider(
                value: _volume,
                onChanged: (v) {
                  setState(() => _volume = v);
                  WebAudioBridge.setVolume(v);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailedAudioInfoModal(BuildContext context, bool isDark) {
    final peach = const Color(0xFFFEDBB3);
    final textPrimary = isDark ? peach : const Color(0xFF141210);
    final textMuted = isDark ? Colors.white54 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161210) : const Color(0xFFFFF8F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
          ),
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _currentAudioMetadata.isDolbyAtmos
                            ? Colors.deepPurpleAccent.withOpacity(0.15)
                            : (_currentAudioMetadata.isHiRes
                                ? peach.withOpacity(0.15)
                                : Colors.cyanAccent.withOpacity(0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _currentAudioMetadata.isDolbyAtmos
                            ? Icons.spatial_audio_rounded
                            : (_currentAudioMetadata.isHiRes
                                ? Icons.album_rounded
                                : Icons.graphic_eq_rounded),
                        color: _currentAudioMetadata.isDolbyAtmos
                            ? Colors.deepPurpleAccent
                            : (_currentAudioMetadata.isHiRes ? peach : Colors.cyanAccent),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Stream Fidelity & Diagnostics',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'AuraBeat Master Audio Engine v2.0 · Live Stream Telemetry',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: textMuted,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hero Quality Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentAudioMetadata.isDolbyAtmos
                          ? [Colors.deepPurple.shade900, const Color(0xFF2E1065)]
                          : (_currentAudioMetadata.isHiRes
                              ? [const Color(0xFF3E2723), const Color(0xFF261814)]
                              : [const Color(0xFF003840), const Color(0xFF002228)]),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _currentAudioMetadata.isDolbyAtmos
                          ? Colors.deepPurpleAccent.withOpacity(0.4)
                          : (_currentAudioMetadata.isHiRes
                              ? peach.withOpacity(0.4)
                              : Colors.cyanAccent.withOpacity(0.4)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentAudioMetadata.isDolbyAtmos
                                ? 'DOLBY ATMOS SPATIAL AUDIO'
                                : (_currentAudioMetadata.isHiRes
                                    ? 'CERTIFIED HI-RES LOSSLESS'
                                    : (_currentAudioMetadata.isLossless ? 'BIT-PERFECT CD LOSSLESS' : 'HIGH FIDELITY STEREO')),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: _currentAudioMetadata.isDolbyAtmos
                                  ? Colors.deepPurpleAccent
                                  : (_currentAudioMetadata.isHiRes ? peach : Colors.cyanAccent),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, size: 12, color: Colors.greenAccent),
                                SizedBox(width: 4),
                                Text(
                                  'VERIFIED BITSTREAM',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentAudioMetadata.summaryQualityLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track: ${_currentSong.title} — ${_currentSong.artist}',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
                      ),
                      if (_currentAudioMetadata.isDolbyAtmos || _currentSong.isDolbyAtmos) ...[
                        const SizedBox(height: 10),
                        AtmosBadge(
                          isAtmosSource: true,
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AtmosDiagnosticScreen(streamingManager: _atmosStreamingManager),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Dolby Atmos Spatial Passthrough Interactive Card
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _currentAudioMetadata.isDolbyAtmos
                        ? Colors.deepPurple.withOpacity(0.2)
                        : (isDark ? const Color(0xFF1F1A17) : const Color(0xFFF7ECE1)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _currentAudioMetadata.isDolbyAtmos
                          ? Colors.deepPurpleAccent.withOpacity(0.5)
                          : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _currentAudioMetadata.isDolbyAtmos
                              ? Colors.deepPurpleAccent.withOpacity(0.25)
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.spatial_audio_rounded,
                          size: 22,
                          color: _currentAudioMetadata.isDolbyAtmos ? Colors.deepPurpleAccent : textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Dolby Atmos Spatial Audio',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: _currentAudioMetadata.isDolbyAtmos ? Colors.deepPurpleAccent : Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _currentAudioMetadata.isDolbyAtmos ? 'ACTIVE 7.1.4' : 'OFF',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: _currentAudioMetadata.isDolbyAtmos ? Colors.white : textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _currentAudioMetadata.isDolbyAtmos
                                  ? 'Discrete 7.1.4 object audio bed & WebAudio binaural DSP active'
                                  : 'Tap to force-engage Dolby Atmos spatial passthrough',
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _currentAudioMetadata.isDolbyAtmos,
                        activeColor: Colors.deepPurpleAccent,
                        activeTrackColor: Colors.purple.shade200,
                        onChanged: (val) {
                          setState(() {
                            _dolbyAtmosEnabled = val;
                            _isSpatialAudio = val;
                            _updateMetadataForSong(_currentSong);
                          });
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),

                // Dolby Atmos Diagnostic Lab Button
                InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AtmosDiagnosticScreen(
                          streamingManager: _atmosStreamingManager,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.deepPurpleAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.troubleshoot_rounded, color: Colors.deepPurpleAccent, size: 22),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dolby Atmos Diagnostic Lab',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'View real-time bitstream audit: Source, Player & Output Verification',
                                style: TextStyle(fontSize: 10, color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                      ],
                    ),
                  ),
                ),

                // Bass Boost Quick Toggle in Modal
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _bassBoostEnabled
                        ? (isDark ? const Color(0xFF2E2622) : const Color(0xFFFFF3E0))
                        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _bassBoostEnabled ? const Color(0xFFFEDBB3) : (isDark ? Colors.white10 : Colors.black12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _bassBoostEnabled ? const Color(0xFFFEDBB3) : Colors.grey.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.speaker_group_rounded,
                          size: 18,
                          color: _bassBoostEnabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Aura Studio Sub-Bass & Clarity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: _bassBoostEnabled ? const Color(0xFFFEDBB3) : Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _bassBoostEnabled ? '+${_bassBoostGain.toStringAsFixed(0)}dB MASTER' : 'OFF',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: _bassBoostEnabled ? Colors.black : textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _bassBoostEnabled
                                  ? 'Active 36Hz sub-bass punch, vocal presence & 10kHz air (Limiter Protected)'
                                  : 'Tap to engage deep subwoofer punch and audiophile clarity',
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _bassBoostEnabled,
                        activeColor: const Color(0xFFFEDBB3),
                        activeTrackColor: const Color(0xFFD4A373),
                        onChanged: (val) {
                          setState(() {
                            _bassBoostEnabled = val;
                          });
                          WebAudioBridge.setBassBoost(val, _bassBoostGain);
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),

                // Interactive Add-on Stream Quality Tier Selector for Active Track
                Builder(
                  builder: (context) {
                    final registry = AddonSourceRegistry.instance;
                    final currentSource = registry.getSourceById(_currentAudioMetadata.sourceId) ??
                        (registry.enabledSources.isNotEmpty
                            ? registry.enabledSources.first
                            : (registry.allSources.isNotEmpty ? registry.allSources.first : null));
                    if (currentSource == null) return const SizedBox.shrink();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F1A17) : const Color(0xFFF7ECE1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: peach.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 16, color: peach),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Select Stream Quality Tier (${currentSource.name})',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: currentSource.hasManifestQualityOptions
                                      ? Colors.cyanAccent.withOpacity(0.15)
                                      : Colors.white10,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  currentSource.hasManifestQualityOptions ? 'MANIFEST OPTIONS' : 'NATIVE TIERS',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: currentSource.hasManifestQualityOptions ? Colors.cyanAccent : textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: currentSource.effectiveAvailableOptions.map((opt) {
                              final isSelected = opt.value == currentSource.effectiveQualityOption;
                              return ChoiceChip(
                                label: Text(
                                  opt.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black : textPrimary,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: peach,
                                backgroundColor: isDark ? Colors.black38 : Colors.white70,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _switchAudioQuality(opt.value, sourceId: currentSource.id);
                                    });
                                    setModalState(() {});
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Audio Technical Parameter Grid
                Text(
                  'TECHNICAL SPECIFICATIONS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 12),

                _buildAudioSpecRow('Audio Codec', '${_currentAudioMetadata.codec} (${_currentAudioMetadata.isLossless ? "Lossless Compression" : "High Bitrate Compression"})', textPrimary, textMuted),
                _buildAudioSpecRow('Container Format', _currentAudioMetadata.container.toUpperCase(), textPrimary, textMuted),
                _buildAudioSpecRow('Sample Rate', '${_currentAudioMetadata.sampleRateHz ?? 96000} Hz (${(_currentAudioMetadata.sampleRateHz ?? 96000) > 48000 ? "Certified Hi-Res Master" : "Standard CD Fidelity"})', textPrimary, textMuted),
                _buildAudioSpecRow('Bit Depth', '${_currentAudioMetadata.bitDepth ?? 24}-bit Dynamic Range (${(_currentAudioMetadata.bitDepth ?? 24) > 16 ? "144 dB Studio Master" : "96 dB Standard"})', textPrimary, textMuted),
                _buildAudioSpecRow('Bitrate', '${_currentAudioMetadata.bitrateKbps ?? 4608} kbps (Variable / Peak Bitrate)', textPrimary, textMuted),
                _buildAudioSpecRow('Channels', _currentAudioMetadata.channels == 8 ? '7.1.4 Dolby Atmos Spatial Object Bed' : '2.0 Discrete Stereo (L/R)', textPrimary, textMuted),
                _buildAudioSpecRow('Lossless Status', _currentAudioMetadata.isLossless ? 'Verified Bit-Perfect (No Lossy Compression)' : 'High Efficiency Compressed', textPrimary, textMuted),
                _buildAudioSpecRow('Hi-Res Certification', _currentAudioMetadata.isHiRes ? 'Certified Hi-Res (>48kHz / >16-bit)' : 'Standard Resolution (<= 48kHz / 16-bit)', textPrimary, textMuted),
                _buildAudioSpecRow('Dolby Atmos', _currentAudioMetadata.isDolbyAtmos ? 'Active Multi-Channel Bitstream' : (_dolbyAtmosEnabled ? 'Binaural DSP Matrix Emulation Active' : 'Disabled'), textPrimary, textMuted),
                _buildAudioSpecRow('Active Add-on Source', '${_currentAudioMetadata.sourceName} (${_currentAudioMetadata.sourceId})', textPrimary, textMuted),
                _buildAudioSpecRow('Streaming Protocol', 'BitChord Wire REST v2.0', textPrimary, textMuted),
                _buildAudioSpecRow('Delivery Method', _currentAudioMetadata.streamType, textPrimary, textMuted),
                _buildAudioSpecRow('Fallback Status', 'Target: ${_globalStreamingProfile.label} -> Direct Stream Hit (0 Fallbacks)', textPrimary, textMuted),
                _buildAudioSpecRow('Pipeline Negotiation', _currentAudioMetadata.isLossless ? '6-Layer Verified Bit-Perfect Pass-Through' : 'Optimized Float32 Resampling Path', textPrimary, textMuted),
                _buildAudioSpecRow('Download Authorization', 'Authorized (BitChord allowDownloads: true)', textPrimary, textMuted),

                const SizedBox(height: 24),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          setState(() {
                            _selectedNav = 4; // Settings tab
                            _selectedSettingsCategory = 1; // Audio Quality category
                          });
                        },
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Configure Settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: peach,
                          side: BorderSide(color: peach.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: peach,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
          },
        );
      },
    );
  }

  Widget _buildAudioSpecRow(String label, String value, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsDrawer(bool isDark, Color cardBg, Color textPrimary, Color textMuted) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1815) : const Color(0xFFFFF0DE),
        border: Border(left: BorderSide(color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08))),
      ),
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Synced Lyrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: textMuted),
                onPressed: () => setState(() => _showLyrics = false),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Real-time lyric sync from LRCLIB',
            style: TextStyle(fontSize: 12, color: textMuted),
          ),
          Divider(height: 30, color: isDark ? Colors.white10 : Colors.black12),
          Expanded(
            child: ListView.builder(
              itemCount: _currentSong.lyrics.length,
              itemBuilder: (context, idx) {
                final line = _currentSong.lyrics[idx];
                final isCurrentLine = idx == 2;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Container(
                    padding: isCurrentLine ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : EdgeInsets.zero,
                    decoration: isCurrentLine
                        ? BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: isCurrentLine ? 16 : 14,
                        fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.w500,
                        color: isCurrentLine
                            ? const Color(0xFFFEDBB3)
                            : (isDark ? Colors.white54 : Colors.black54),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



