import 'package:flutter/material.dart';
import 'package:notestoself/widgets/setting_item_card.dart';

class AnimatedSettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;
  final Animation<double> animation;
  final int index;

  const AnimatedSettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.animation,
    required this.index,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.15;
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
      child: SettingItemCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        isDestructive: isDestructive,
      ),
    );
  }
}
