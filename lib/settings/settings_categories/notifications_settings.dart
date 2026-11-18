import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Playback Notifications'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('Download Notifications'),
            value: true,
            onChanged: (val) {},
          ),
          SwitchListTile(
            title: const Text('App Notifications'),
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }
}