import 'package:flutter/material.dart';

class AnimatedOptionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDestructive;
  final VoidCallback onTap;
  final Animation<double> animation;
  final int index;

  const AnimatedOptionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.animation,
    required this.index,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.1;
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(delay.clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: itemAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: itemAnimation,
          child: Transform.translate(
            offset: Offset(0, (1 - itemAnimation.value) * 20),
            child: child,
          ),
        );
      },
      child: _buildOptionContent(context),
    );
  }

  Widget _buildOptionContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: isDestructive
              ? colorScheme.error.withValues(alpha: 0.1)
              : colorScheme.primary.withValues(alpha: 0.1),
          highlightColor: isDestructive
              ? colorScheme.error.withValues(alpha: 0.05)
              : colorScheme.primary.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                          color: isDestructive
                              ? colorScheme.error
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
