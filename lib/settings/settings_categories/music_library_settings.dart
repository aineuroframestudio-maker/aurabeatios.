import 'package:flutter/material.dart';

class MusicLibrarySettingsScreen extends StatelessWidget {
  const MusicLibrarySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Library Settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Scan Music Library'),
            leading: const Icon(Icons.sync),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Refresh Library'),
            leading: const Icon(Icons.refresh),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Folder Management'),
            leading: const Icon(Icons.folder),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Metadata Preferences'),
            leading: const Icon(Icons.label),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Album Artwork'),
            leading: const Icon(Icons.art_track),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Sorting Preferences'),
            leading: const Icon(Icons.sort),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Library Organization'),
            leading: const Icon(Icons.library_music),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Duplicate Detection'),
            leading: const Icon(Icons.content_copy),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}