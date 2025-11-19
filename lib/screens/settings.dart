import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/note.dart';
import '../utils/database_helper.dart';
import '../widgets/confirmation_dialog.dart';
import '../widgets/animated_setting_item.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _staggerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _staggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
      );
      final tempDir = await getTemporaryDirectory();
      final backupFile = File(
        '${tempDir.path}/notes_backup_${DateTime.now().toIso8601String()}.json',
      );
      await backupFile.writeAsString(jsonData);

      await SharePlus.instance.share(
        ShareParams(text: 'Notes Backup', files: [XFile(backupFile.path)]),
      );

      if (context.mounted) {
        _showSnackBar(context, 'Backup shared successfully', isError: false);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Backup failed: $e', isError: true);
      }
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

      if (context.mounted) {
        _showSnackBar(context, 'Restore successful!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Restore failed: $e', isError: true);
      }
    }
  }

  Future<void> _clearAllData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Clear All Data',
        content: 'This will delete all notes permanently. Are you sure?',
        confirmButtonText: 'Clear',
        cancelButtonText: 'Cancel',
        isDestructive: true,
      ),
    );

    if (confirmed == true) {
      try {
        final db = await DatabaseHelper.instance.database;
        await db.delete('notes');
        if (context.mounted) {
          _showSnackBar(context, 'All data cleared', isError: false);
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar(context, 'Clear failed: $e', isError: true);
        }
      }
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: isError
            ? colorScheme.error
            : colorScheme.inverseSurface,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: _staggerAnimation,
        builder: (context, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 8),
              AnimatedSettingItem(
                icon: Icons.backup,
                title: 'Backup to JSON',
                subtitle: 'Export all notes as a JSON file and share it',
                onTap: () => _backupToJson(context),
                animation: _animationController,
                index: 0,
              ),
              AnimatedSettingItem(
                icon: Icons.restore,
                title: 'Restore from JSON',
                subtitle:
                    'Import notes from a JSON backup file (overwrites existing data)',
                onTap: () => _restoreFromJson(context),
                animation: _animationController,
                index: 1,
              ),
              AnimatedSettingItem(
                icon: Icons.delete_forever,
                title: 'Clear All Data',
                subtitle: 'Permanently delete all notes',
                onTap: () => _clearAllData(context),
                animation: _animationController,
                index: 2,
                isDestructive: true,
              ),
            ],
          );
        },
      ),
    );
  }
}
