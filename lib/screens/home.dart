import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../utils/database_helper.dart';
import '../utils/date_formats.dart';
import 'notes_to_self.dart';
import 'settings.dart';
import '../widgets/animated_date_card.dart';
import '../widgets/loading_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/animated_search_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<String> _datesSorted = [];
  Map<String, int> _noteCounts = {};
  Map<String, List<String>> _noteTextsByDay = {};

  String _searchQuery = '';
  bool _loading = true;
  bool _hasAutoOpened = false;
  bool _isSearching = false;

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _titleAnimationController;
  late Animation<double> _titleScaleAnimation;

  late AnimationController _cardAnimationController;
  late Animation<double> _cardStaggerAnimation;

  @override
  void initState() {
    super.initState();

    _titleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _titleScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _titleAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _cardStaggerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _loadAllNotes();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _titleAnimationController.forward();
      _cardAnimationController.forward();
    });
  }

  Future<void> _loadAllNotes() async {
    final counts = await DatabaseHelper.instance.getNoteCounts();
    final dates = counts.keys.toList();
    final todayKey = keyFormat.format(DateTime.now());

    if (!counts.containsKey(todayKey)) {
      dates.insert(0, todayKey);
      counts[todayKey] = 0;
    }

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
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            NotesToSelfPage(
              dateKey: dateKey,
              initialNotes: notes,
              displayDate: displayFormat.format(DateTime.parse(dateKey)),
              isToday: dateKey == keyFormat.format(DateTime.now()),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    ).then((_) => _loadAllNotes());
  }

  void _openSettings() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTitle() {
    return AnimatedBuilder(
      animation: _titleAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _titleScaleAnimation.value,
          child: Text(
            'Notes to Self',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: _isSearching
            ? AnimatedSearchField(
                controller: _searchController,
                hintText: 'Search notes...',
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
                onClose: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _isSearching = false;
                  });
                },
              )
            : _buildAnimatedTitle(),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 3,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        surfaceTintColor: Colors.transparent,
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _isSearching
                ? const SizedBox.shrink()
                : IconButton(
                    icon: Icon(Icons.search, color: colorScheme.onSurface),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
                  ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _loading
            ? const LoadingState(message: 'Loading your notes...')
            : _displayDates.isEmpty
            ? _buildEmptyState()
            : _buildAnimatedList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isEmpty) {
      return EmptyState(
        title: 'No notes yet',
        subtitle: 'Add your first note to get started',
        icon: Icons.note_add_outlined,
        buttonText: 'Create First Note',
        onButtonPressed: () {
          final todayKey = keyFormat.format(DateTime.now());
          _openDayNotes(todayKey, autoFocus: true);
        },
      );
    } else {
      return const EmptyState(
        title: 'No matching notes found',
        icon: Icons.search_off,
      );
    }
  }

  Widget _buildAnimatedList() {
    return AnimatedBuilder(
      animation: _cardStaggerAnimation,
      builder: (context, child) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: _displayDates.length,
          itemBuilder: (context, idx) {
            final delay = idx * 0.1;
            final itemAnimation = CurvedAnimation(
              parent: _cardAnimationController,
              curve: Interval(
                delay.clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutCubic,
              ),
            );

            final key = _displayDates[idx];
            final count = _noteCounts[key] ?? 0;
            final displayDate = displayFormat.format(DateTime.parse(key));

            return AnimatedDateCard(
              dateKey: key,
              displayDate: displayDate,
              noteCount: count,
              isToday: key == keyFormat.format(DateTime.now()),
              onTap: () => _openDayNotes(key),
              animation: itemAnimation,
            );
          },
        );
      },
    );
  }
}
