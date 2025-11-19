import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';

class NoteBubble extends StatelessWidget {
  final Note note;
  final int index;
  final bool isToday;
  final Animation<double> animation;
  final VoidCallback onLongPress;
  final VoidCallback onReply;
  final bool showReplyButton;

  const NoteBubble({
    super.key,
    required this.note,
    required this.index,
    required this.isToday,
    required this.animation,
    required this.onLongPress,
    required this.onReply,
    this.showReplyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, (1 - animation.value) * 20),
            child: child,
          ),
        );
      },
      child: _buildNoteContent(context),
    );
  }

  Widget _buildNoteContent(BuildContext context) {
    final timeFormatted = DateFormat('hh:mm a').format(note.createdAt);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (note.text.startsWith('↪')) ...[
                    _buildReplyContext(context),
                    const SizedBox(height: 6),
                  ],

                  Text(
                    note.text.startsWith('↪')
                        ? note.text.substring(note.text.indexOf('\n') + 1)
                        : note.text,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeFormatted,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (isToday && showReplyButton)
                        GestureDetector(
                          onTap: onReply,
                          child: Icon(
                            Icons.reply_rounded,
                            size: 14,
                            color: colorScheme.onPrimaryContainer.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyContext(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final originalNote = note.text.substring(2, note.text.indexOf('\n'));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.onPrimaryContainer.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              originalNote,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
