import 'package:flutter/material.dart';
import '../settings_service.dart';

class LosslessHiResSettingsScreen extends StatefulWidget {
  const LosslessHiResSettingsScreen({super.key});

  @override
  State<LosslessHiResSettingsScreen> createState() => _LosslessHiResSettingsScreenState();
}

class _LosslessHiResSettingsScreenState extends State<LosslessHiResSettingsScreen> {
  Map<String, dynamic> _losslessInfo = {};

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final info = await SettingsService.getLosslessInfo();
    setState(() => _losslessInfo = info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lossless & Hi-Res Audio')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Lossless Audio'),
            subtitle: Text(_losslessInfo['supported'] as String? ?? 'Supported'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            title: const Text('Hi-Res Audio'),
            subtitle: Text(_losslessInfo['hires'] as String? ?? 'Supported'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          ListTile(
            title: const Text('Supported Sample Rates'),
            subtitle: Text(_losslessInfo['sampleRates'] as String? ?? '44.1/48/96/192 kHz'),
          ),
          ListTile(
            title: const Text('Supported Bit Depths'),
            subtitle: Text(_losslessInfo['bitDepths'] as String? ?? '16/24-bit'),
          ),
          ListTile(
            title: const Text('Audio Format Compatibility'),
            subtitle: Text(_losslessInfo['formats'] as String? ?? 'FLAC/ALAC/WAV/AIFF'),
          ),
        ],
      ),
    );
  }
}