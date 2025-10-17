import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../services/database_helper.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<List<Note>> _getAllNotes() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('notes', orderBy: 'created_at ASC');
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> _backupToJson(BuildContext context) async {
    try {
      final allNotes = await _getAllNotes();
      final jsonData = jsonEncode(
        allNotes.map((n) => n.toMap()..remove('id')).toList(),
      ); // Remove id for portability
      final tempDir = await getTemporaryDirectory();
      final backupFile = File(
        '${tempDir.path}/notes_backup_${DateTime.now().toIso8601String()}.json',
      );
      await backupFile.writeAsString(jsonData);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          text: 'Notes To Self Backup',
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup shared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    }
  }

  Future<void> _restoreFromJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final notes = jsonList.map((map) => Note.fromMap(map)).toList();

      final db = await DatabaseHelper.instance.database;
      await db.transaction((txn) async {
        await txn.delete('notes');
        for (var note in notes) {
          await txn.insert('notes', {
            'text': note.text,
            'created_at': note.createdAt.toIso8601String(),
          });
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Restore successful.')));

      Navigator.pop(context, true); // ✅ Trigger refresh
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all notes permanently. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('notes');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All data cleared')));
        Navigator.pop(context, true); // ✅ Trigger refresh
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Clear failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup to JSON'),
            subtitle: const Text(
              'Export all notes as a JSON file and share it',
            ),
            onTap: () => _backupToJson(context),
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from JSON'),
            subtitle: const Text(
              'Import notes from a JSON backup file (overwrites existing data)',
            ),
            onTap: () => _restoreFromJson(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear All Data'),
            subtitle: const Text('Permanently delete all notes'),
            onTap: () => _clearAllData(context),
          ),
        ],
      ),
    );
  }
}
