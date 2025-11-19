import 'package:flutter/material.dart';
import '../models/note.dart';

class ReplyHeader extends StatelessWidget {
  final Note? replyingNote;
  final VoidCallback onClose;
  final Animation<double> slideAnimation;
  final Animation<double> opacityAnimation;

  const ReplyHeader({
    super.key,
    required this.replyingNote,
    required this.onClose,
    required this.slideAnimation,
    required this.opacityAnimation,
  });

  @override
  Widget build(BuildContext context) {
    if (replyingNote == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([slideAnimation, opacityAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: Opacity(opacity: opacityAnimation.value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            Icon(Icons.reply_rounded, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replying to note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    replyingNote!.text,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            IconButton(
              onPressed: onClose,
              icon: Icon(
                Icons.close,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
