import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedDateCard extends StatelessWidget {
  final String dateKey;
  final String displayDate;
  final int noteCount;
  final bool isToday;
  final VoidCallback onTap;
  final Animation<double> animation;

  const AnimatedDateCard({
    super.key,
    required this.dateKey,
    required this.displayDate,
    required this.noteCount,
    required this.isToday,
    required this.onTap,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ScaleTransition(
      scale: Tween<double>(
        begin: 0.8,
        end: 1.0,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.elasticOut)),
      child: FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Card(
            elevation: 0,
            color: isToday
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              splashColor: colorScheme.primary.withValues(alpha: 0.1),
              highlightColor: colorScheme.primary.withValues(alpha: 0.05),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    _buildDateIndicator(colorScheme, isToday),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayDate,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$noteCount note${noteCount != 1 ? 's' : ''}',
                            style: textTheme.bodyMedium?.copyWith(
                              color:
                                  (isToday
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurface)
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color:
                          (isToday
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface)
                              .withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateIndicator(ColorScheme colorScheme, bool isToday) {
    final date = DateTime.parse(dateKey);
    final day = date.day.toString();
    final month = DateFormat('MMM').format(date);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: isToday
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
          Text(
            month,
            style: TextStyle(
              fontSize: 10,
              color: isToday ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
