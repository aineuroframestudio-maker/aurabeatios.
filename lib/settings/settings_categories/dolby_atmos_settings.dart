import 'package:flutter/material.dart';
import '../settings_service.dart';

class DolbyAtmosSettingsScreen extends StatefulWidget {
  const DolbyAtmosSettingsScreen({super.key});

  @override
  State<DolbyAtmosSettingsScreen> createState() => _DolbyAtmosSettingsScreenState();
}

class _DolbyAtmosSettingsScreenState extends State<DolbyAtmosSettingsScreen> {
  Map<String, dynamic> _atmosInfo = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await SettingsService.getDolbyAtmosInfo();
    setState(() => _atmosInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dolby Atmos & Spatial Audio')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dolby Atmos Availability'),
            subtitle: Text(_atmosInfo['available'] as String? ?? 'Available'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            title: const Text('Spatial Audio'),
            subtitle: Text(_atmosInfo['spatial'] as String? ?? 'Supported'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            title: const Text('Supported Formats'),
            subtitle: Text(_atmosInfo['formats'] as String? ?? 'E-AC-3 JOC / AAC-Spatial'),
          ),
          ListTile(
            title: const Text('Playback Status'),
            subtitle: Text(_atmosInfo['status'] as String? ?? 'Ready'),
          ),
          ListTile(
            title: const Text('Processing Status'),
            subtitle: Text(_atmosInfo['processing'] as String? ?? 'Native BitChord Engine'),
          ),
        ],
      ),
    );
  }
}