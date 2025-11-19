import 'package:flutter/material.dart';

class SendButton extends StatelessWidget {
  final bool isEnabled;
  final bool isEditing;
  final VoidCallback onSend;
  final Animation<Color?> colorAnimation;
  final Animation<double> scaleAnimation;
  final Animation<double> elevationAnimation;

  const SendButton({
    super.key,
    required this.isEnabled,
    required this.isEditing,
    required this.onSend,
    required this.colorAnimation,
    required this.scaleAnimation,
    required this.elevationAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([
        colorAnimation,
        scaleAnimation,
        elevationAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Material(
            elevation: elevationAnimation.value,
            shape: const CircleBorder(),
            color: isEnabled
                ? colorAnimation.value
                : colorScheme.onSurface.withValues(alpha: 0.12),
            child: InkWell(
              onTap: isEnabled ? onSend : null,
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  isEditing ? Icons.edit : Icons.send,
                  color: isEnabled
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.38),
                  size: 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
