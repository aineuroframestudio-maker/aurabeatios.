import 'package:flutter/material.dart';
import '../settings_service.dart';

class AudioPlaybackSettingsScreen extends StatefulWidget {
  const AudioPlaybackSettingsScreen({super.key});

  @override
  State<AudioPlaybackSettingsScreen> createState() => _AudioPlaybackSettingsScreenState();
}

class _AudioPlaybackSettingsScreenState extends State<AudioPlaybackSettingsScreen> {
  int _audioQuality = 3;
  bool _gapless = false;
  bool _crossfade = false;
  bool _replayGain = false;
  bool _volumeNormalization = false;
  bool _backgroundPlayback = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final quality = await SettingsService.getAudioQuality();
    final gapless = await SettingsService.getGapless();
    final crossfade = await SettingsService.getCrossfade();
    final replayGain = await SettingsService.getReplayGain();
    final volumeNorm = await SettingsService.getVolumeNormalization();
    final background = await SettingsService.getBackgroundPlayback();

    setState(() {
      _audioQuality = quality;
      _gapless = gapless;
      _crossfade = crossfade;
      _replayGain = replayGain;
      _volumeNormalization = volumeNorm;
      _backgroundPlayback = background;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio & Playback Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Audio Quality'),
            subtitle: const Text('Choose audio output quality'),
            trailing: Text(_audioQuality == 1 ? 'Low' : _audioQuality == 3 ? 'High' : 'Medium'),
            onTap: () => _showQualityDialog(context),
          ),
          SwitchListTile(
            title: const Text('Gapless Playback'),
            subtitle: const Text('Continue playback without pauses'),
            value: _gapless,
            onChanged: (val) async {
              await SettingsService.setGapless(val);
              setState(() => _gapless = val);
            },
          ),
          SwitchListTile(
            title: const Text('Crossfade'),
            subtitle: const Text('Fade between tracks smoothly'),
            value: _crossfade,
            onChanged: (val) async {
              await SettingsService.setCrossfade(val);
              setState(() => _crossfade = val);
            },
          ),
          SwitchListTile(
            title: const Text('ReplayGain'),
            subtitle: const Text('Normalize audio levels'),
            value: _replayGain,
            onChanged: (val) async {
              await SettingsService.setReplayGain(val);
              setState(() => _replayGain = val);
            },
          ),
          SwitchListTile(
            title: const Text('Volume Normalization'),
            subtitle: const Text('Keep consistent volume levels'),
            value: _volumeNormalization,
            onChanged: (val) async {
              await SettingsService.setVolumeNormalization(val);
              setState(() => _volumeNormalization = val);
            },
          ),
          SwitchListTile(
            title: const Text('Background Playback'),
            subtitle: const Text('Continue playing when app is in background'),
            value: _backgroundPlayback,
            onChanged: (val) async {
              await SettingsService.setBackgroundPlayback(val);
              setState(() => _backgroundPlayback = val);
            },
          ),
        ],
      ),
    );
  }

  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Audio Quality'),
        content: Column(
          children: [
            RadioListTile(
              value: 1,
              groupValue: _audioQuality,
              title: const Text('Low (64 kbps)'),
              onChanged: (val) async {
                await SettingsService.setAudioQuality(1);
                if (!mounted) return;
                setState(() => _audioQuality = 1);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            RadioListTile(
              value: 2,
              groupValue: _audioQuality,
              title: const Text('Medium (128 kbps)'),
              onChanged: (val) async {
                await SettingsService.setAudioQuality(2);
                if (!mounted) return;
                setState(() => _audioQuality = 2);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
            RadioListTile(
              value: 3,
              groupValue: _audioQuality,
              title: const Text('High (256 kbps)'),
              onChanged: (val) async {
                await SettingsService.setAudioQuality(3);
                if (!mounted) return;
                setState(() => _audioQuality = 3);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }
}