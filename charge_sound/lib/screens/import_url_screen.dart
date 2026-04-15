import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../models/sound_item.dart';
import '../providers/user_files_provider.dart';
import '../utils/app_audio_dirs.dart';
import '../utils/audio_duration_probe.dart';

class ImportUrlScreen extends ConsumerStatefulWidget {
  const ImportUrlScreen({super.key});

  @override
  ConsumerState<ImportUrlScreen> createState() => _ImportUrlScreenState();
}

class _ImportUrlScreenState extends ConsumerState<ImportUrlScreen> {
  final _urlController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final raw = _urlController.text.trim();
    if (raw.isEmpty) return;
    Uri uri;
    try {
      uri = Uri.parse(raw);
    } catch (_) {
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Download failed (${response.statusCode})');
      }
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('audio') &&
          !uri.path.endsWith('.mp3') &&
          !uri.path.endsWith('.m4a') &&
          !uri.path.endsWith('.wav')) {
        throw Exception('URL is not an audio resource.');
      }
      final dir = await ensureUserFilesDirectory();
      final ext = p.extension(uri.path).isEmpty ? '.mp3' : p.extension(uri.path);
      final path =
          '${dir.path}/url_${DateTime.now().millisecondsSinceEpoch}$ext';
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);
      final duration = await probeAudioFileDuration(path);
      final item = SoundItem(
        id: 'url_${DateTime.now().millisecondsSinceEpoch}',
        name: p.basenameWithoutExtension(path),
        path: path,
        duration: duration,
        source: SoundSource.file,
        createdAt: DateTime.now(),
      );
      await ref.read(userFilesProvider.notifier).add(item);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from URL')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Audio URL',
                hintText: 'https://example.com/sound.mp3',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _import,
              child: Text(_loading ? 'Importing…' : 'Import'),
            ),
          ],
        ),
      ),
    );
  }
}
