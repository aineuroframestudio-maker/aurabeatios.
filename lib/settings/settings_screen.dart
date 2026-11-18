import 'package:flutter/material.dart';
import 'settings_categories/general_settings.dart';
import 'settings_categories/audio_playback_settings.dart';
import 'settings_categories/equalizer_settings.dart';
import 'settings_categories/lossless_hires_settings.dart';
import 'settings_categories/dolby_atmos_settings.dart';
import 'settings_categories/sony_360_settings.dart';
import 'settings_categories/music_library_settings.dart';
import 'settings_categories/online_services_settings.dart';
import 'settings_categories/downloads_storage_settings.dart';
import 'settings_categories/notifications_settings.dart';
import 'settings_categories/privacy_security_settings.dart';
import 'settings_categories/about_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(context, 'General', Icons.palette, () => const GeneralSettingsScreen()),
          _buildSection(context, 'Audio & Playback', Icons.audio_file, () => const AudioPlaybackSettingsScreen()),
          _buildSection(context, 'Equalizer & Audio Effects', Icons.equalizer, () => const EqualizerSettingsScreen()),
          _buildSection(context, 'Lossless & Hi-Res Audio', Icons.hd, () => const LosslessHiResSettingsScreen()),
          _buildSection(context, 'Dolby Atmos & Spatial Audio', Icons.spatial_audio, () => const DolbyAtmosSettingsScreen()),
          _buildSection(context, 'Sony 360 Reality Audio', Icons.music_note, () => const Sony360SettingsScreen()),
          _buildSection(context, 'Music Library', Icons.library_music, () => const MusicLibrarySettingsScreen()),
          _buildSection(context, 'Online Services & Integrations', Icons.cloud, () => const OnlineServicesSettingsScreen()),
          _buildSection(context, 'Downloads & Storage', Icons.download, () => const DownloadsStorageSettingsScreen()),
          _buildSection(context, 'Notifications', Icons.notifications, () => const NotificationsSettingsScreen()),
          _buildSection(context, 'Privacy & Security', Icons.security, () => const PrivacySecuritySettingsScreen()),
          _buildSection(context, 'About AuraBeat', Icons.info, () => const AboutSettingsScreen()),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, Widget Function() screenBuilder) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screenBuilder()),
          );
        },
      ),
    );
  }
}