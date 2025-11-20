import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/note.dart';
import '../utils/database_helper.dart';
import '../widgets/reply_header.dart';
import '../widgets/note_bubble.dart';
import '../widgets/send_button.dart';
import '../widgets/constant_animation.dart';

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
    with TickerProviderStateMixin {
  late List<Note> _notes;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isEditing = false;
  int? _editIndex;

  late AnimationController _animController;
  late Animation<Color?> _buttonColorAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonElevationAnimation;

  late AnimationController _entryAnimationController;

  late AnimationController _replyAnimationController;
  late Animation<double> _replySlideAnimation;
  late Animation<double> _replyOpacityAnimation;

  final FocusNode _inputFocusNode = FocusNode();
  Note? _replyingNote;

  @override
  void initState() {
    super.initState();
    _notes = List.from(widget.initialNotes);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _replyAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _buttonColorAnimation = ConstantAnimation(Colors.transparent);
    _buttonScaleAnimation = ConstantAnimation(1.0);
    _buttonElevationAnimation = ConstantAnimation(0.0);
    _replySlideAnimation = ConstantAnimation(0.0);
    _replyOpacityAnimation = ConstantAnimation(0.0);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        FocusScope.of(context).requestFocus(_inputFocusNode);
        _scrollToBottom();
        _entryAnimationController.forward();
      }
    });

    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final colorScheme = Theme.of(context).colorScheme;

    _buttonColorAnimation =
        ColorTween(
          begin: colorScheme.primary.withValues(alpha: 0.7),
          end: colorScheme.primary,
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
        );

    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _buttonElevationAnimation = Tween<double>(begin: 0.0, end: 4.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _replySlideAnimation = Tween<double>(begin: -60.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _replyAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _replyOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _replyAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _setReplyingNote(Note? note) {
    setState(() {
      _replyingNote = note;
    });

    if (note != null) {
      _replyAnimationController.forward();
      FocusScope.of(context).requestFocus(_inputFocusNode);
    } else {
      _replyAnimationController.reverse();
    }
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
        _setReplyingNote(null);
      } else {
        newNote = Note(text: finalText, createdAt: now);
        _notes.add(newNote);
        _setReplyingNote(null);
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
      _showSnackBar('Editing is only allowed within 5 minutes');
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
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Note',
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note?',
          style: TextStyle(
            color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(ctx).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      ),
    );
  }

  void _showNoteOptions(Note note, int index, bool canEdit) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      useSafeArea: true,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => _NoteOptionsBottomSheet(
        note: note,
        index: index,
        canEdit: canEdit,
        isToday: widget.isToday,
        colorScheme: Theme.of(context).colorScheme,
        textTheme: Theme.of(context).textTheme,
        onActionSelected: (action) => Navigator.pop(context, action),
        onReply: () => _setReplyingNote(note),
      ),
    );

    if (action != null) {
      switch (action) {
        case 'copy':
          _performCopyAction(note);
          break;
        case 'edit':
          _startEditing(index);
          break;
        case 'delete':
          _deleteNote(index);
          break;
        case 'reply':
          _setReplyingNote(note);
          break;
      }
    }
  }

  void _performCopyAction(Note note) {
    Clipboard.setData(ClipboardData(text: note.text));
    _showEnhancedSnackBar('Copied to clipboard', icon: Icons.check);
  }

  void _showEnhancedSnackBar(String message, {IconData? icon}) {
    final cs = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: cs.onInverseSurface),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: cs.inverseSurface,
        elevation: 6,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _animController.dispose();
    _entryAnimationController.dispose();
    _replyAnimationController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canEditOrAdd = _canAddOrEdit();
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.displayDate),
        backgroundColor: cs.surface,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            ReplyHeader(
              replyingNote: _replyingNote,
              onClose: () => _setReplyingNote(null),
              slideAnimation: _replySlideAnimation,
              opacityAnimation: _replyOpacityAnimation,
            ),

            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    itemCount: _notes.length,
                    itemBuilder: (context, idx) {
                      final delay = idx * 0.1;
                      final itemAnimation = CurvedAnimation(
                        parent: _entryAnimationController,
                        curve: Interval(
                          delay.clamp(0.0, 1.0),
                          1.0,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                      final note = _notes[idx];
                      final canEdit =
                          DateTime.now().difference(note.createdAt) <=
                          const Duration(minutes: 5);

                      return NoteBubble(
                        note: note,
                        index: idx,
                        isToday: widget.isToday,
                        animation: itemAnimation,
                        onLongPress: () => _showNoteOptions(note, idx, canEdit),
                        onReply: () => _setReplyingNote(note),
                        showReplyButton: true,
                      );
                    },
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surface,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _inputFocusNode,
                            maxLines: null,
                            textInputAction: TextInputAction.newline,
                            enabled: canEditOrAdd,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: _replyingNote != null
                                  ? 'Replying...'
                                  : canEditOrAdd
                                  ? 'Type your note...'
                                  : 'Cannot edit past notes',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            style: textTheme.bodyMedium,
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
                          }
                        },
                        onTapCancel: () {
                          if (canEditOrAdd && hasText) {
                            _animController.reverse();
                          }
                        },
                        child: SendButton(
                          isEnabled: canEditOrAdd && hasText,
                          isEditing: _isEditing,
                          onSend: _sendNote,
                          colorAnimation: _buttonColorAnimation,
                          scaleAnimation: _buttonScaleAnimation,
                          elevationAnimation: _buttonElevationAnimation,
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

class _NoteOptionsBottomSheet extends StatefulWidget {
  final Note note;
  final int index;
  final bool canEdit;
  final bool isToday;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final Function(String) onActionSelected;
  final VoidCallback onReply;

  const _NoteOptionsBottomSheet({
    required this.note,
    required this.index,
    required this.canEdit,
    required this.isToday,
    required this.colorScheme,
    required this.textTheme,
    required this.onActionSelected,
    required this.onReply,
  });

  @override
  State<_NoteOptionsBottomSheet> createState() =>
      _NoteOptionsBottomSheetState();
}

class _NoteOptionsBottomSheetState extends State<_NoteOptionsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: widget.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: widget.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: widget.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.more_horiz,
                    color: widget.colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note Options',
                        style: widget.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Choose an action for this note',
                        style: widget.textTheme.bodySmall?.copyWith(
                          color: widget.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.note.text,
                    style: widget.textTheme.bodyMedium?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.note_outlined,
                  size: 16,
                  color: widget.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildOptionTile(
            context,
            title: 'Reply',
            subtitle: 'Reply to this note',
            icon: Icons.reply_rounded,
            onTap: () {
              Navigator.pop(context, 'reply');
            },
            show: widget.isToday,
          ),

          _buildOptionTile(
            context,
            title: 'Copy',
            subtitle: 'Copy note text to clipboard',
            icon: Icons.copy,
            onTap: () {
              Navigator.pop(context, 'copy');
            },
            show: true,
          ),

          _buildOptionTile(
            context,
            title: 'Edit',
            subtitle: 'Edit this note',
            icon: Icons.edit,
            onTap: () {
              Navigator.pop(context, 'edit');
            },
            show: widget.canEdit && widget.isToday,
          ),

          _buildOptionTile(
            context,
            title: 'Delete',
            subtitle: 'Permanently delete this note',
            icon: Icons.delete,
            onTap: () {
              Navigator.pop(context, 'delete');
            },
            show: true,
            isDestructive: true,
          ),

          const SizedBox(height: 8),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: widget.colorScheme.surfaceContainerHigh,
                foregroundColor: widget.colorScheme.onSurface,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text('Close', style: widget.textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool show,
    bool isDestructive = false,
  }) {
    if (!show) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? colorScheme.errorContainer
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: widget.textTheme.bodyLarge?.copyWith(
          color: isDestructive ? colorScheme.error : colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: widget.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}
