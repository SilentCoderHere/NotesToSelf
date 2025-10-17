import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/note.dart';
import '../services/database_helper.dart';

class NotesToSelfPage extends StatefulWidget {
  final String dateKey;
  final List<Note> initialNotes;
  final String displayDate;
  final bool isToday;

  const NotesToSelfPage({
    super.key,
    required this.dateKey,
    required this.initialNotes,
    required this.displayDate,
    required this.isToday,
  });

  @override
  State<NotesToSelfPage> createState() => _NotesToSelfPageState();
}

class _NotesToSelfPageState extends State<NotesToSelfPage>
    with SingleTickerProviderStateMixin {
  late List<Note> _notes;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEditing = false;
  int? _editIndex;

  late AnimationController _animController;
  Animation<Color?>? _buttonColorAnimation;

  final FocusNode _inputFocusNode = FocusNode();

  Note? _replyingNote;

  @override
  void initState() {
    super.initState();
    _notes = List.from(widget.initialNotes);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        FocusScope.of(context).requestFocus(_inputFocusNode);
        _scrollToBottom();
      }
    });
    _controller.addListener(() {
      setState(() {}); // Update send button state
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cs = Theme.of(context).colorScheme;

    _buttonColorAnimation = ColorTween(
      begin: cs.primary.withValues(alpha: 0.5),
      end: cs.primary,
    ).animate(_animController);
  }

  bool _canAddOrEdit() {
    if (!widget.isToday) return false;

    if (_isEditing && _editIndex != null) {
      final noteTime = _notes[_editIndex!].createdAt;
      return DateTime.now().difference(noteTime) <= const Duration(minutes: 5);
    }
    return true;
  }

  void _sendNote() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    String finalText = text;
    if (_replyingNote != null) {
      finalText = "↪ ${_replyingNote!.text}\n$text";
    }

    final now = DateTime.now();
    late Note newNote;

    setState(() {
      if (_isEditing && _editIndex != null) {
        var oldNote = _notes[_editIndex!];
        newNote = oldNote.copyWith(text: finalText, createdAt: now);
        _notes[_editIndex!] = newNote;
        _isEditing = false;
        _editIndex = null;
        _replyingNote = null;
      } else {
        newNote = Note(text: finalText, createdAt: now);
        _notes.add(newNote);
        _replyingNote = null;
      }
    });

    if (newNote.id != null) {
      await DatabaseHelper.instance.updateNote(newNote);
    } else {
      final id = await DatabaseHelper.instance.insertNote(newNote);
      setState(() {
        final index = _notes.indexOf(newNote);
        if (index != -1) {
          _notes[index] = newNote.copyWith(id: id);
        }
      });
    }

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _startEditing(int index) {
    if (!_canAddOrEdit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Editing is only allowed within 5 minutes'),
        ),
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _editIndex = index;
      _controller.text = _notes[index].text;
      FocusScope.of(context).requestFocus(_inputFocusNode);
    });
  }

  void _deleteNote(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final id = _notes[index].id;
    if (id != null) {
      await DatabaseHelper.instance.deleteNote(id);
    }

    setState(() {
      _notes.removeAt(index);
      if (_isEditing && _editIndex == index) {
        _isEditing = false;
        _editIndex = null;
        _controller.clear();
      }
    });
  }

  Widget _buildNoteBubble(Note note) {
    final timeFormatted = DateFormat('hh:mm a').format(note.createdAt);
    final cs = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(note.id ?? note.createdAt.toIso8601String()),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade800],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: const [
            Icon(Icons.reply, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Swipe to Reply',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        setState(() {
          _replyingNote = note;
        });
        FocusScope.of(context).requestFocus(_inputFocusNode);
        return false;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () async {
                final canEdit =
                    DateTime.now().difference(note.createdAt) <=
                    const Duration(minutes: 5);

                final action = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.copy),
                        title: const Text('Copy'),
                        onTap: () => Navigator.pop(context, 'copy'),
                      ),
                      if (canEdit)
                        ListTile(
                          leading: const Icon(Icons.edit),
                          title: const Text('Edit'),
                          onTap: () => Navigator.pop(context, 'edit'),
                        ),
                      ListTile(
                        leading: const Icon(Icons.delete),
                        title: const Text('Delete'),
                        onTap: () => Navigator.pop(context, 'delete'),
                      ),
                    ],
                  ),
                );

                switch (action) {
                  case 'copy':
                    Clipboard.setData(ClipboardData(text: note.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                    break;
                  case 'edit':
                    _startEditing(_notes.indexOf(note));
                    break;
                  case 'delete':
                    _deleteNote(_notes.indexOf(note));
                    break;
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cs.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      note.text,
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeFormatted,
                      style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canEditOrAdd = _canAddOrEdit();
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(widget.displayDate)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  itemCount: _notes.length,
                  itemBuilder: (context, idx) => _buildNoteBubble(_notes[idx]),
                ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingNote != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _replyingNote!.text,
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _replyingNote = null;
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocusNode,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          enabled: canEditOrAdd,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type your note...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTapDown: (_) {
                          if (canEditOrAdd && hasText) {
                            _animController.forward();
                          }
                        },
                        onTapUp: (_) {
                          if (canEditOrAdd && hasText) {
                            _animController.reverse();
                            _sendNote();
                          }
                        },
                        onTapCancel: () {
                          if (canEditOrAdd) _animController.reverse();
                        },
                        child: AnimatedBuilder(
                          animation: _animController,
                          builder: (context, child) {
                            return CircleAvatar(
                              radius: 26,
                              backgroundColor: canEditOrAdd && hasText
                                  ? (_buttonColorAnimation?.value ?? cs.primary)
                                  : cs.onSurface.withValues(alpha: 0.3),
                              child: Icon(
                                _isEditing ? Icons.edit : Icons.send,
                                color: cs.onPrimary,
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
