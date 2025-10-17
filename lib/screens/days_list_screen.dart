import 'package:flutter/material.dart';

import '../services/database_helper.dart';
import '../utils/date_formats.dart';
import 'notes_to_self_screen.dart';
import 'settings_screen.dart';

class DaysListPage extends StatefulWidget {
  const DaysListPage({super.key});

  @override
  State<DaysListPage> createState() => _DaysListPageState();
}

class _DaysListPageState extends State<DaysListPage> {
  List<String> _datesSorted = [];
  Map<String, int> _noteCounts = {};
  Map<String, List<String>> _noteTextsByDay = {};

  String _searchQuery = '';
  bool _loading = true;
  bool _hasAutoOpened = false;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllNotes();
  }

  Future<void> _loadAllNotes() async {
    final counts = await DatabaseHelper.instance.getNoteCounts();
    final dates = counts.keys.toList(); // Sorted DESC from db helper
    final todayKey = keyFormat.format(DateTime.now());

    // Ensure today is in the list
    if (!counts.containsKey(todayKey)) {
      dates.insert(0, todayKey);
      counts[todayKey] = 0;
    }

    // Load note texts by day for filtering
    Map<String, List<String>> textsMap = {};
    for (var key in dates) {
      final notes = await DatabaseHelper.instance.getNotesForDay(key);
      textsMap[key] = notes.map((n) => n.text).toList();
    }

    setState(() {
      _datesSorted = dates;
      _noteCounts = counts;
      _noteTextsByDay = textsMap;
      _loading = false;
    });

    // Auto-open today page with keyboard
    if (!_hasAutoOpened) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openDayNotes(todayKey, autoFocus: true);
        _hasAutoOpened = true;
      });
    }
  }

  List<String> get _displayDates {
    if (_searchQuery.trim().isEmpty) return _datesSorted;

    final query = _searchQuery.toLowerCase();
    return _datesSorted.where((dayKey) {
      final notes = _noteTextsByDay[dayKey] ?? [];
      return notes.any((note) => note.toLowerCase().contains(query));
    }).toList();
  }

  void _openDayNotes(String dateKey, {bool autoFocus = false}) async {
    final notes = await DatabaseHelper.instance.getNotesForDay(dateKey);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotesToSelfPage(
          dateKey: dateKey,
          initialNotes: notes,
          displayDate: displayFormat.format(DateTime.parse(dateKey)),
          isToday: dateKey == keyFormat.format(DateTime.now()),
        ),
      ),
    ).then((_) => _loadAllNotes());
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsPage()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search notes...',
                  border: InputBorder.none,
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              )
            : const Text('Notes to Self'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _displayDates.isEmpty
          ? const Center(
              child: Text(
                'No matching notes found.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _displayDates.length,
              itemBuilder: (context, idx) {
                final key = _displayDates[idx];
                final count = _noteCounts[key] ?? 0;
                final displayDate = displayFormat.format(DateTime.parse(key));

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ListTile(
                      onTap: () => _openDayNotes(key),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                      title: Text(
                        displayDate,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '$count note${count != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
